//
//  ImageSliderViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/13/19.
//

import UIKit

class ImageSliderViewController: Widget {
    override var currentState: WidgetState {
        willSet {
            previousState = self.currentState
        }
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetDidEnterState(widget: self, state: self.currentState)
                switch self.currentState {
                case .ready:
                    break
                case .interacting:
                    self.enterInteractingState()
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }
    
    override var dismissSwipeableView: UIView {
        return self.imageSliderView.titleView
    }
    
    private let averageAnimationSeconds: CGFloat = 2
    private let additionalResultsSeconds: Double = 5

    private var latestAverageMagnitude: Float?
    private var closeButtonAction: (() -> Void)?
    private let model: ImageSliderWidgetModel
    private var sliderChangedCount: Int = 0
    private var firstTimeSliderChanged: Date?

    private lazy var imageSliderView: ImageSliderView = {
        var imageUrls = self.model.options.map({ $0.imageURL })

        let initialSliderValue = self.model.initialMagnitude
        let imageSliderView = ImageSliderView(
            thumbImageUrls: imageUrls,
            initialSliderValue: Float(initialSliderValue),
            timerAnimationFilepath: self.theme.lottieFilepaths.timer
        )
        imageSliderView.translatesAutoresizingMaskIntoConstraints = false
        imageSliderView.sliderView.addTarget(self, action: #selector(imageSliderViewValueChanged), for: .touchUpInside)

        return imageSliderView
    }()

    private var timerDuration: TimeInterval?
    private var interactionTimer: Timer?

    // MARK: - Init

    override init(model: ImageSliderWidgetModel) {
        self.model = model
        super.init(model: model)
        NotificationCenter.default.addObserver(self, selector: #selector(didMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func didMoveToForeground() {
        // Restart the timer animation from continuous time since background
        // We need to do this because when Lottie goes into background it pauses the animation
        if
            let interactionTimer = interactionTimer,
            let lottieAnimation = imageSliderView.timerView.animation,
            let duration = timerDuration
        {
            let timeRemaining = interactionTimer.fireDate.timeIntervalSince(Date())
            let timeScalar = lottieAnimation.duration / duration

            imageSliderView.timerView.currentTime = (duration - timeRemaining) * timeScalar
            imageSliderView.timerView.play()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        enterReadyState()
        configureView()
        self.model.delegate = self
        self.model.registerImpression()
    }
    
    override func moveToNextState() {
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
    
    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        self.closeButtonAction = {
            completion(self)
        }
        self.imageSliderView.closeButton.isHidden = false
    }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        timerDuration = seconds
        interactionTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            completion(self)
        })

        imageSliderView.timerView.animationSpeed = CGFloat(imageSliderView.timerView.animation?.duration ?? 0) / CGFloat(seconds)
        imageSliderView.timerView.isHidden = false
        imageSliderView.timerView.play { [weak self] finished in
            if finished {
                self?.imageSliderView.timerView.isHidden = true
            }
        }
    }
    
    // MARK: - Private Method

    private func configureView() {
        imageSliderView.avgIndicatorView.animationSpeed = CGFloat(imageSliderView.timerView.animation?.duration ?? 0) / CGFloat(averageAnimationSeconds)
        imageSliderView.coreWidgetView.baseView.clipsToBounds = true
        imageSliderView.coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        imageSliderView.bodyView.backgroundColor = theme.widgetBodyColor
        let title: String = {
            var title = model.question
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

    @objc private func closeButtonSelected() {
        closeButtonAction?()
    }

    @objc private func imageSliderViewValueChanged() {
        self.userDidInteract = true

        let now = Date()
        if firstTimeSliderChanged == nil {
            firstTimeSliderChanged = now
        }
        timeOfLastInteraction = now
        sliderChangedCount += 1
        self.delegate?.userDidInteract(self)
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
        self.interactableState = .openToInteraction
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        if
            let firstTimeSliderChanged = self.firstTimeSliderChanged,
            let lastTimeSliderChanged = self.timeOfLastInteraction
        {
            let props = WidgetInteractedProperties(
                widgetId: self.model.id,
                widgetKind: self.model.kind.analyticsName,
                firstTapTime: firstTimeSliderChanged,
                lastTapTime: lastTimeSliderChanged,
                numberOfTaps: self.sliderChangedCount
            )
            self.model.eventRecorder.record(.widgetInteracted(programID: model.programID, properties: props))
        }

        let magnitude = self.imageSliderView.sliderView.value
        log.info("Submitting vote with magnitude: \(magnitude)")
        self.imageSliderView.timerView.isHidden = true
        self.lockSlider()
        self.interactableState = .closedToInteraction

        // can complete results if user did not interact
        guard self.sliderChangedCount > 0 else {
            showPreviouslyVotedResults()
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }

        self.model.lockInVote(magnitude: Double(magnitude)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case.success:
                log.info("Successfully submitted image slider vote.")
            case .failure:
                log.error("Failed to submit image slider vote.")
            }

            // Delay needed to wait for a more accurate result from server
            delay(2.0) { [weak self] in
                guard let self = self else { return }
                let magnitude = self.imageSliderView.sliderView.value
                // if user didn't recieve latest average magnitude from server then use their magnitude as average
                // this will likely be the case for the first user to receive this widget
                let avgMagnitude = self.latestAverageMagnitude ?? magnitude
                self.imageSliderView.averageVote = avgMagnitude

                self.playAverageAnimation { [weak self] in
                    guard let self = self else { return }
                    self.imageSliderView.showResultsTrack()
                    delay(self.additionalResultsSeconds) { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                    }
                }
            }
        }
    }
    
    private func enterFinishedState() {
        if sliderChangedCount == 0 {
            showPreviouslyVotedResults()
        }
        
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.imageSliderView.refreshAverageAnimationLeadingConstraint()
        })
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    /// Shows average magnitude from already existing votes
    private func showPreviouslyVotedResults() {
        let avgMagnitudeFloat = Float(model.averageMagnitude)
        self.imageSliderView.averageVote = avgMagnitudeFloat

        self.playAverageAnimation { [weak self] in
            guard let self = self else { return }
            self.imageSliderView.moveSliderThumb(to: avgMagnitudeFloat)
        }
   }
}

extension ImageSliderViewController: ImageSliderWidgetModelDelegate {
    func imageSliderWidgetModel(
        _ model: ImageSliderWidgetModel,
        averageMagnitudeDidChange averageMagnitude: Double
    ) {
        self.latestAverageMagnitude = Float(averageMagnitude)
    }
}
