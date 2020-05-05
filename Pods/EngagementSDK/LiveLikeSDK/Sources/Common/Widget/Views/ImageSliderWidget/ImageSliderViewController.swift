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
    
    var coreWidgetView: CoreWidgetView {
        return imageSliderView.coreWidgetView
    }
    
    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }

    var dismissSwipeableView: UIView {
        return self.imageSliderView.titleView
    }

    private let averageAnimationSeconds: CGFloat = 2
    private let additionalResultsSeconds: Double = 5

    private let imageSliderCreated: ImageSliderCreated
    private let cache: Cache = Cache.shared
    private let voteClient: ImageSliderVoteClient
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private var resultsClient: ImageSliderResultsClient
    private var whenVotingLocked = Promise<Float>()
    private var latestAverageMagnitude: Float?

    // MARK: Analytics Properties

    private let eventRecorder: EventRecorder
    private var firstTimeSliderChanged: Date?
    private var lastTimeSliderChanged: Date?
    private var sliderChangedCount: Int = 0
    private var timeDisplayed = Date()

    private lazy var imageSliderView: ImageSliderView = {
        var images = [UIImage]()
        for option in self.imageSliderCreated.options {
            self.cache.get(key: option.imageUrl.absoluteString) { (data: Data?) in
                guard let data = data else { return }
                guard let image = UIImage.decode(data) else { return }
                images.append(image)
            }
        }

        let initialSliderValue = self.imageSliderCreated.initialMagnitude.number ?? 0
        let imageSliderView = ImageSliderView(
            thumbImages: images,
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
                let widgetInteractedProperties = WidgetInteractedProperties(
                    widgetId: self.imageSliderCreated.id,
                    widgetKind: self.kind.analyticsName,
                    firstTapTime: firstTimeSliderChanged,
                    lastTapTime: lastTimeSliderChanged,
                    numberOfTaps: self.sliderChangedCount,
                    interactionTimeInterval: self.interactionTimeInterval,
                    widgetViewModel: self
                )
                self.delegate?.widgetInteractionDidComplete(properties: widgetInteractedProperties)
            }

            // if user didn't recieve latest average magnitude from server then use their magnitude as average
            // this will likely be the case for the first user to receive this widget
            let avgMagnitude = self.latestAverageMagnitude ?? myMagnitude
            self.imageSliderView.averageVote = avgMagnitude

            self.playAverageAnimation {
                self.imageSliderView.showResultsTrack()
                delay(self.additionalResultsSeconds) { [weak self] in
                    self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
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
        configureView()
    }

    func start() {
        // widget displayed analytics
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: imageSliderCreated.id))

        imageSliderView.timerView.play { finished in
            if finished {
                self.imageSliderView.timerView.isHidden = true
                self.lockSlider()

                if !self.widgetConfig.isAutoDismissEnabled {
                    // play results early if auto dismiss disabled
                    self.whenVotingLocked.fulfill(self.latestAverageMagnitude ?? 0.5)
                } else if self.sliderChangedCount == 0 {
                    // return early if user didn't change slider
                    self.delegate?.actionHandler(event: .dismiss(action: .timeout))
                }

                if self.widgetConfig.isManualDismissButtonEnabled {
                    self.imageSliderView.closeButton.isHidden = false
                }
                
                // vote
                let magnitude = self.imageSliderView.sliderView.value
                log.info("Submitting vote with magnitude: \(magnitude)")
                
                firstly {
                    self.voteClient.vote(url: self.imageSliderCreated.voteUrl, magnitude: magnitude)
                }.then { _ in
                    log.info("Successfully submitted image slider vote.")
                }.catch { _ in
                    log.error("Failed to submit image slider vote.")
                }.always { [weak self] in 
                    // Delay needed to wait for a more accurate result from server
                    delay(2.0) {
                        self?.whenVotingLocked.fulfill(magnitude)
                    }
                }
            }
        }
        delegate?.widgetInteractionDidBegin(widget: self)
    }

    // MARK: - Private Method

    private func configureView() {
        imageSliderView.timerView.animationSpeed = CGFloat(imageSliderView.timerView.animation?.duration ?? 0) / CGFloat(imageSliderCreated.timeout.timeInterval)
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
        delegate?.actionHandler(event: .dismiss(action: .tapX))
    }

    @objc private func imageSliderViewValueChanged() {
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
}

extension ImageSliderViewController: ImageSliderResultsDelegate {
    func resultsClient(didReceiveResults results: ImageSliderResults) {
        guard let averageMagnitude = results.averageMagnitude?.number else { return }
        latestAverageMagnitude = Float(averageMagnitude)
    }
}
