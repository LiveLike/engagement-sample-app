//
//  ImageSliderViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/13/19.
//

import UIKit

class ImageSliderViewController: WidgetController {
    var id: String
    var kind: WidgetKind
    weak var delegate: WidgetEvents?
    var widgetTitle: String?
    let interactionTimeInterval: TimeInterval?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var customData: String?
    var userDidInteract: Bool = false
    var previousState: WidgetState?
    var currentState: WidgetState = .ready {
        willSet {
            previousState = self.currentState
        }
        didSet {
            self.delegate?.widgetDidEnterState(widget: self, state: currentState)
            switch currentState {
            case .ready:
                break
            case .interacting:
                enterInteractingState()
            case .results:
                enterResultsState()
            case .finished:
                enterFinishedState()
            }
        }
    }
    
    var dismissSwipeableView: UIView {
        return self.imageSliderView.titleView
    }

    private let averageAnimationSeconds: CGFloat = 2
    private let additionalResultsSeconds: Double = 5

    private let imageSliderCreated: ImageSliderCreated
    private let voteClient: ImageSliderVoteClient
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private var resultsClient: ImageSliderResultsClient
    private var whenVotingLocked = Promise<Float>()
    private var latestAverageMagnitude: Float?
    private var closeButtonAction: (() -> Void)?

    // MARK: Analytics Properties

    private let eventRecorder: EventRecorder
    private var firstTimeSliderChanged: Date?
    private var lastTimeSliderChanged: Date?
    private var sliderChangedCount: Int = 0
    private var timeDisplayed = Date()

    private lazy var imageSliderView: ImageSliderView = {
        var imageUrls = self.imageSliderCreated.options.map({ $0.imageUrl })

        let initialSliderValue = self.imageSliderCreated.initialMagnitude.number ?? 0
        let imageSliderView = ImageSliderView(
            thumbImageUrls: imageUrls,
            initialSliderValue: Float(initialSliderValue),
            timerAnimationFilepath: self.theme.filepathsForWidgetTimerLottieAnimation
        )
        imageSliderView.translatesAutoresizingMaskIntoConstraints = false
        imageSliderView.sliderView.addTarget(self, action: #selector(imageSliderViewValueChanged), for: .touchUpInside)

        return imageSliderView
    }()

    // MARK: - Init

    init(imageSliderCreated: ImageSliderCreated,
         resultsClient: ImageSliderResultsClient,
         imageSliderVoteClient: ImageSliderVoteClient,
         theme: Theme,
         eventRecorder: EventRecorder,
         widgetConfig: WidgetConfig,
         title: String = "",
         options: Set<WidgetOption> = Set()
    ) {
        id = imageSliderCreated.id
        self.imageSliderCreated = imageSliderCreated
        self.resultsClient = resultsClient
        self.theme = theme
        self.eventRecorder = eventRecorder
        self.widgetConfig = widgetConfig
        voteClient = imageSliderVoteClient
        kind = imageSliderCreated.kind
        self.widgetTitle = title
        self.options = options
        self.interactionTimeInterval = imageSliderCreated.timeout.timeInterval
        self.customData = imageSliderCreated.customData
        super.init(nibName: nil, bundle: nil)

        /*
         Waits for voting to be locked and results to be received
         Then reveals the results and auto dismisses the widget
         **/
        
        self.resultsClient.delegate = self
        
        whenVotingLocked.then { [weak self] myMagnitude in
            guard let self = self else { return }
            
            // widget interacted analytics
            if let firstTimeSliderChanged = self.firstTimeSliderChanged, let lastTimeSliderChanged = self.lastTimeSliderChanged {
                _ = WidgetInteractedProperties(
                    widgetId: self.imageSliderCreated.id,
                    widgetKind: self.kind.analyticsName,
                    firstTapTime: firstTimeSliderChanged,
                    lastTapTime: lastTimeSliderChanged,
                    numberOfTaps: self.sliderChangedCount,
                    interactionTimeInterval: self.interactionTimeInterval,
                    widgetViewModel: self,
                    previousState: .interacting,
                    currentState: .finished
                )
            }

            // if user didn't recieve latest average magnitude from server then use their magnitude as average
            // this will likely be the case for the first user to receive this widget
            let avgMagnitude = self.latestAverageMagnitude ?? myMagnitude
            self.imageSliderView.averageVote = avgMagnitude

            self.playAverageAnimation {
                self.imageSliderView.showResultsTrack()
                delay(self.additionalResultsSeconds) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                }
            }
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        enterReadyState()
        configureView()
    }
    
    func moveToNextState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.currentState {
            case .ready:
                self.currentState = .interacting
            case .interacting:
                self.currentState = .results
            case .results:
                self.currentState = .finished
            case .finished:
                break
            }
        }
    }
    
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        self.closeButtonAction = {
            completion(self)
        }
        self.imageSliderView.closeButton.isHidden = false
    }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        imageSliderView.timerView.animationSpeed = CGFloat(imageSliderView.timerView.animation?.duration ?? 0) / CGFloat(seconds)
        imageSliderView.timerView.play { [weak self] _ in
            guard let self = self else { return }
            completion(self)
        }
    }
    
    // MARK: - Private Method

    private func configureView() {
        imageSliderView.avgIndicatorView.animationSpeed = CGFloat(imageSliderView.timerView.animation?.duration ?? 0) / CGFloat(averageAnimationSeconds)
        imageSliderView.coreWidgetView.baseView.clipsToBounds = true
        imageSliderView.coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        imageSliderView.bodyView.backgroundColor = theme.widgetBodyColor
        let title: String = {
            var title = imageSliderCreated.question
            if theme.uppercaseTitleText {
                title = title.uppercased()
            }
            return title
        }()
        imageSliderView.titleLabel.setWidgetSecondaryText(title, theme: theme, alignment: .left)

        imageSliderView.sliderView.minimumTrackTintColor = theme.imageSlider.trackMinimumTint
        imageSliderView.sliderView.maximumTrackTintColor = theme.imageSlider.trackMaximumTint

        imageSliderView.resultsHotColor = theme.imageSlider.resultsHotColor
        imageSliderView.resultsColdColor = theme.imageSlider.resultsColdColor

        imageSliderView.titleView.backgroundColor = theme.imageSlider.titleBackgroundColor

        imageSliderView.customSliderTrack.livelike_startColor = theme.imageSlider.trackGradientLeft
        imageSliderView.customSliderTrack.livelike_endColor = theme.imageSlider.trackGradientRight

        imageSliderView.titleMargins = theme.imageSlider.titleMargins

        imageSliderView.closeButton.addTarget(self, action: #selector(closeButtonSelected), for: .touchUpInside)

        view.addSubview(imageSliderView)
        imageSliderView.constraintsFill(to: view)
    }

    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            let props = WidgetDismissedProperties(
                widgetId: imageSliderCreated.id,
                widgetKind: kind.analyticsName,
                dismissAction: dismissAction,
                numberOfTaps: sliderChangedCount,
                dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed)
            )
            eventRecorder.record(.widgetUserDismissed(properties: props))
        }
    }

    @objc private func closeButtonSelected() {
        closeButtonAction?()
    }

    @objc private func imageSliderViewValueChanged() {
        self.userDidInteract = true
        // update analytics properties
        let now = Date()
        if firstTimeSliderChanged == nil {
            firstTimeSliderChanged = now
        }
        lastTimeSliderChanged = now
        sliderChangedCount += 1
    }

    private func lockSlider() {
        imageSliderView.sliderView.isUserInteractionEnabled = false
    }

    private func playAverageAnimation(completion: @escaping () -> Void) {
        imageSliderView.avgIndicatorView.play { finished in
            if finished {
                completion()
            }
        }
    }
    
    // MARK: Handle States
    
    private func enterReadyState() {
        imageSliderView.isUserInteractionEnabled = false
        imageSliderView.timerView.isHidden = true
    }
    
    private func enterInteractingState() {
        imageSliderView.isUserInteractionEnabled = true
        imageSliderView.timerView.isHidden = false
        
        // widget displayed analytics
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: imageSliderCreated.id))
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        let magnitude = self.imageSliderView.sliderView.value
        log.info("Submitting vote with magnitude: \(magnitude)")
        self.imageSliderView.timerView.isHidden = true
        self.lockSlider()

        // can complete results if user did not interact
        guard self.sliderChangedCount > 0 else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }
        
        firstly {
            self.voteClient.vote(url: self.imageSliderCreated.voteUrl, magnitude: magnitude)
        }.then { _ in
            log.info("Successfully submitted image slider vote.")
        }.catch { _ in
            log.error("Failed to submit image slider vote.")
        }.always { [weak self] in
            guard let self = self else { return }
            
            // Delay needed to wait for a more accurate result from server
            delay(2.0) { [weak self] in
                guard let self = self else { return }
                let magnitude = self.imageSliderView.sliderView.value
                self.whenVotingLocked.fulfill(magnitude)
            }
        }
    }
    
    private func enterFinishedState() {
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}

extension ImageSliderViewController: ImageSliderResultsDelegate {
    func resultsClient(didReceiveResults results: ImageSliderResults) {
        guard let averageMagnitude = results.averageMagnitude?.number else { return }
        latestAverageMagnitude = Float(averageMagnitude)
    }
}
