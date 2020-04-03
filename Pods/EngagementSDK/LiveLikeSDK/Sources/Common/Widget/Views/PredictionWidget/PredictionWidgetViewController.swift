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
    
    var dismissSwipeableView: UIView {
        return self.view
    }

    // MARK: Private Properties

    private var currentSelectionId: String?
    private var didSelectResponse: Bool = false
    private let widgetData: ChoiceWidgetViewModel
    private let voteRepo: WidgetVotes?
    private let predictionTheme: PredictionWidgetTheme
    private let theme: Theme
    private let style: ChoiceWidgetViewType
    private let predictionWidgetClient: PredictionVoteClient
    private var choiceWidgetOptions = [ChoiceWidgetOptionButton]()

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
         eventRecorder: EventRecorder) {
        self.widgetData = widgetData
        id = widgetData.id
        self.voteRepo = voteRepo
        self.predictionWidgetClient = predictionWidgetClient
        predictionTheme = theme.predictionWidget
        self.theme = theme
        self.kind = kind
        self.style = style
        self.eventRecorder = eventRecorder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view.addSubview(predictionWidgetView)
        predictionWidgetView.constraintsFill(to: view)
        predictionWidgetView.titleView.beginTimer(duration: widgetData.timeout, animationID: widgetData.animationTimerAsset!) { [weak self] in
            self?.interactableState = .closedToInteraction
            self?.widgetWillDismiss(action: .timeout)
        }
    }

    func start() {
        timeDisplayed = Date()
        eventsDelegate?.engagementEvent(.didDisplayWidget)
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: widgetData.id))
    }

    private func onOptionSelected(_ option: ChoiceWidgetOption) {
        didSelectResponse = true
        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        lastTapTime = now
        tapCount += 1
        currentSelectionId = option.id

        deselectAllOptions()
        option.setBorderColor(predictionTheme.optionSelectBorderColor)
        option.isSelected = true
    }

    private func deselectAllOptions() {
        for optionButton in choiceWidgetOptions {
            optionButton.layer.borderColor = theme.neutralOptionColors.borderColor.cgColor
            optionButton.isSelected = false
        }
    }

    // Logic before the widget will animate away
    private func widgetWillDismiss(action: DismissAction) {
        if didSelectResponse {
            // Send vote
            if let voteUrl = self.widgetData.options.first(where: { $0.id == currentSelectionId })?.voteUrl {
                firstly {
                    predictionWidgetClient.vote(url: voteUrl)
                }.then { [weak self] vote in
                    guard let self = self else { return }
                    guard let voteRepo = self.voteRepo else { return }
                    log.debug("Successfully submitted prediction.")
                    voteRepo.addVote(vote, forId: self.widgetData.id)
                    if let firstTapTime = self.firstTapTime, let lastTapTime = self.lastTapTime {
                        let properties = WidgetInteractedProperties(
                            widgetId: self.widgetData.id,
                            widgetKind: self.kind.analyticsName,
                            firstTapTime: firstTapTime,
                            lastTapTime: lastTapTime,
                            numberOfTaps: self.tapCount
                        )
                        self.delegate?.widgetInteractionDidComplete(properties: properties)
                    }
                }.catch { error in
                        log.error("Error: \(error.localizedDescription)")
                }
            }

            // dismiss immediately if user triggered dismissal
            if action.userDismissed {
                delegate?.actionHandler(event: .dismiss(action: action))
            } else {
                // show confirmation message then dismiss
                showActionConfirmation { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.actionHandler(event: .dismiss(action: action))
                }
            }
        } else {
            delegate?.actionHandler(event: .dismiss(action: action))
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

    private func showActionConfirmation(completion: (() -> Void)?) {
        if let confirmationMessage = widgetData.confirmationMessage, let confirmationAsset = widgetData.animationConfirmationAsset {
            let actionConfirmationView = ActionConfirmationView(title: confirmationMessage, animationID: confirmationAsset, duration: 5.0) {
                completion?()
            }
            actionConfirmationView.customize(theme: theme)
            predictionWidgetView.coreWidgetView.alpha = 0.2
            predictionWidgetView.addSubview(actionConfirmationView)
            actionConfirmationView.constraintsFill(to: predictionWidgetView.coreWidgetView)
        }
    }
}
