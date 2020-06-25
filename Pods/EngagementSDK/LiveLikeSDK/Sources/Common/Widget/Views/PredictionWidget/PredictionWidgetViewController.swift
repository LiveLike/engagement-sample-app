//
//  TextPredictionWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-28.
//

import Lottie
import UIKit

/// Game logic for prediction widgets
class PredictionWidgetViewController: WidgetController {

    // MARK: Properties

    var id: String
    var kind: WidgetKind

    weak var delegate: WidgetEvents?
//    weak var eventsDelegate: EngagementEventsDelegate?
    var coreWidgetView: CoreWidgetView {
        return predictionWidgetView.coreWidgetView
    }
    
    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }
    
    var dismissSwipeableView: UIView {
        return self.view
    }

    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var customData: String?
    var interactionTimeInterval: TimeInterval?
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

    // MARK: Private Properties

    private var currentSelection: ChoiceWidgetOption?
    private let widgetData: ChoiceWidgetViewModel
    private let voteRepo: WidgetVotes?
    private let predictionTheme: PredictionWidgetTheme
    private let theme: Theme
    private let style: ChoiceWidgetViewType
    private let predictionWidgetClient: PredictionVoteClient
    private var choiceWidgetOptions = [ChoiceWidgetOptionButton]()
    private var latestResults: PredictionResults?
    private var canShowResults: Bool = false
    private var closeButtonAction: (() -> Void)?
    
    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var firstTapTime: Date?
    private var lastTapTime: Date?
    private var tapCount = 0
    private var timeDisplayed = Date()
    private var interactableState: InteractableState = .openToInteraction

    // MARK: View Properties

    private(set) lazy var predictionWidgetView: ChoiceWidgetView = {
        let textChoiceWidget = VerticalChoiceWidget()
        textChoiceWidget.coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        textChoiceWidget.customize(predictionTheme, theme: theme)
        textChoiceWidget.titleView.titleLabel.text = theme.uppercaseTitleText ? widgetData.question.uppercased() : widgetData.question
        textChoiceWidget.titleView.titleMargins = theme.choiceWidgetTitleMargins
        textChoiceWidget.titleView.closeButton.addTarget(
            self,
            action: #selector(onCloseButtonPressed),
            for: .touchUpInside
        )

        switch style {
        case .text:
            choiceWidgetOptions = widgetData.options.map { option in
                var predictionView = ChoiceWidgetOptionFactory().create(style: .wideText, id: option.id)
                predictionView.customize(theme)
                predictionView.setText(option.text, theme: theme)
                predictionView.onButtonPressed = { [weak self] in self?.onOptionSelected($0) }
                return predictionView
            }
        case .image:
            choiceWidgetOptions = widgetData.options.map { option in
                var predictionView: ChoiceWidgetOptionButton = ChoiceWidgetOptionFactory().create(style: .wideTextImage, id: option.id)
                predictionView.customize(theme)
                predictionView.setText(option.text, theme: theme)
                if let imageURL = option.imageUrl {
                    predictionView.setImage(imageURL)
                }
                predictionView.onButtonPressed = { [weak self] in self?.onOptionSelected($0) }
                return predictionView
            }
        }

        textChoiceWidget.populateStackView(options: choiceWidgetOptions)
        return textChoiceWidget
    }()

    init(style: ChoiceWidgetViewType,
         kind: WidgetKind,
         widgetData: ChoiceWidgetViewModel,
         voteRepo: WidgetVotes?,
         theme: Theme,
         predictionWidgetClient: PredictionVoteClient,
         eventRecorder: EventRecorder,
         title: String = "",
         options: Set<WidgetOption> = Set()
    ) {
        self.widgetData = widgetData
        id = widgetData.id
        self.voteRepo = voteRepo
        self.predictionWidgetClient = predictionWidgetClient
        predictionTheme = theme.predictionWidget
        self.theme = theme
        self.kind = kind
        self.style = style
        self.eventRecorder = eventRecorder
        self.widgetTitle = title
        self.options = options
        self.interactionTimeInterval = widgetData.timeout
        self.customData = widgetData.customData
        super.init(nibName: nil, bundle: nil)
        
        self.predictionWidgetView.isUserInteractionEnabled = false
        
        self.predictionWidgetClient.didRecieveResults = { [weak self] results in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.latestResults = results

                if self.canShowResults {
                    self.updateResults(results: results)
                }
            }
            
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view.addSubview(predictionWidgetView)
        predictionWidgetView.constraintsFill(to: view)
        
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
        self.closeButtonAction = { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
        predictionWidgetView.titleView.showCloseButton()
    }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        predictionWidgetView.titleView.beginTimer(
            duration: widgetData.timeout,
            animationFilepath: theme.filepathsForWidgetTimerLottieAnimation
        ) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }

    private func enterInteractingState(){
        self.predictionWidgetView.isUserInteractionEnabled = true
        timeDisplayed = Date()
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: widgetData.id))
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        self.predictionWidgetView.coreWidgetView.contentView?.isUserInteractionEnabled = false
        self.interactableState = .closedToInteraction
         
        guard let selectedOption = self.currentSelection else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }
                        
        guard let selectionWidgetData = self.widgetData.options.first(where: { $0.id == selectedOption.id}) else {
            log.error("Couldn't find widget data for option with id \(selectedOption.id)")
            return
        }
        
        // Send vote
        firstly {
            self.predictionWidgetClient.vote(url: selectionWidgetData.voteUrl)
        }.then { [weak self] vote in
            guard let self = self else { return }
            guard let voteRepo = self.voteRepo else { return }
            self.canShowResults = true
            log.debug("Successfully submitted prediction.")
            voteRepo.addVote(vote, forId: self.widgetData.id)
            
            // show progress on all options with latest results
            if let latestResults = self.latestResults {
                self.updateResults(results: latestResults)
            }
            
            if let firstTapTime = self.firstTapTime, let lastTapTime = self.lastTapTime {
                let properties = WidgetInteractedProperties(
                    widgetId: self.widgetData.id,
                    widgetKind: self.kind.analyticsName,
                    firstTapTime: firstTapTime,
                    lastTapTime: lastTapTime,
                    numberOfTaps: self.tapCount,
                    interactionTimeInterval: self.interactionTimeInterval,
                    widgetViewModel: self,
                    previousState: .interacting,
                    currentState: .finished
                )
            }
            
            if let animationFilepath = self.theme.predictionWidget.lottieAnimationOnTimerCompleteFilepaths.randomElement() {
                self.predictionWidgetView.playOverlayAnimation(animationFilepath: animationFilepath) {
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                }
            }
        }.catch { error in
            log.error("Error: \(error.localizedDescription)")
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
        }
    }
    
    private func enterFinishedState() {
        predictionWidgetView.stopOverlayAnimation()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
    
    @objc private func onCloseButtonPressed() {
        self.closeButtonAction?()
    }

    private func onOptionSelected(_ option: ChoiceWidgetOption) {
        self.userDidInteract = true
        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        lastTapTime = now
        tapCount += 1
        currentSelection = option

        deselectAllOptions()
        option.setBorderColor(predictionTheme.optionSelectBorderColor)
        option.isSelected = true
    }
    
    private func updateResults(results: PredictionResults) {
        let totalVotes = results.options.map{ $0.voteCount }.reduce(0, +)
        
        guard totalVotes > 0 else { return }
        
        self.choiceWidgetOptions.forEach { option in
            guard let optionResult = results.options.first(where: { $0.id == option.id }) else { return }
            let progress: CGFloat = CGFloat(optionResult.voteCount) / CGFloat(totalVotes)
            option.setProgress(progress)
            
            if let currentSelection = self.currentSelection, currentSelection.id == option.id {
                option.setColors(self.theme.predictionWidget.optionGradientColors)
            } else {
                option.setColors(self.theme.neutralOptionColors)
            }
        }
    }

    private func deselectAllOptions() {
        for optionButton in choiceWidgetOptions {
            optionButton.layer.borderColor = theme.neutralOptionColors.borderColor.cgColor
            optionButton.isSelected = false
        }
    }

    func willDismiss(dismissAction: DismissAction) {
        // Log widget dismissed event
        if dismissAction.userDismissed {
            var properties = WidgetDismissedProperties(
                widgetId: widgetData.id,
                widgetKind: kind.analyticsName,
                dismissAction: dismissAction,
                numberOfTaps: tapCount,
                dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed)
            )
            if let lastTapTime = self.lastTapTime {
                properties.dismissSecondsSinceLastTap = Date().timeIntervalSince(lastTapTime)
            }
            properties.interactableState = interactableState
            eventRecorder.record(.widgetUserDismissed(properties: properties))
        }
    }
}
