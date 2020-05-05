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
    weak var eventsDelegate: EngagementEventsDelegate?
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
        predictionWidgetView.titleView.beginTimer(
            duration: widgetData.timeout,
            animationFilepath: theme.filepathsForWidgetTimerLottieAnimation
        ) { [weak self] in
            self?.interactableState = .closedToInteraction
            self?.widgetWillDismiss(action: .timeout)
        }
    }

    func start() {
        timeDisplayed = Date()
        eventsDelegate?.engagementEvent(.didDisplayWidget)
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: widgetData.id))
        delegate?.widgetInteractionDidBegin(widget: self)
    }

    private func onOptionSelected(_ option: ChoiceWidgetOption) {
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

    // Logic before the widget will animate away
    private func widgetWillDismiss(action: DismissAction) {
        guard let selectedOption = self.currentSelection else {
            delegate?.actionHandler(event: .dismiss(action: action))
            return
        }
        
        guard let selectionWidgetData = self.widgetData.options.first(where: { $0.id == selectedOption.id}) else {
            log.error("Couldn't find widget data for option with id \(selectedOption.id)")
            delegate?.actionHandler(event: .dismiss(action: action))
            return
        }
        
        // Send vote
        firstly {
            predictionWidgetClient.vote(url: selectionWidgetData.voteUrl)
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
                    widgetViewModel: self
                )
                self.delegate?.widgetInteractionDidComplete(properties: properties)
            }
        }.catch { error in
                log.error("Error: \(error.localizedDescription)")
        }

        // dismiss immediately if user triggered dismissal
        if action.userDismissed {
            delegate?.actionHandler(event: .dismiss(action: action))
        } else {
            // show confirmation message then dismiss
            if let animationFilepath = self.theme.predictionWidget.lottieAnimationOnTimerCompleteFilepaths.randomElement() {
                predictionWidgetView.playOverlayAnimation(animationFilepath: animationFilepath)
            }
            delay(6) { [weak self] in
                guard let self = self else { return }
                self.delegate?.actionHandler(event: .dismiss(action: action))
            }
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
