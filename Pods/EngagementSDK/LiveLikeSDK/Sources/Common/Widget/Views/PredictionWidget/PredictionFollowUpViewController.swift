//
//  PredictionFollowUpViewController.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/22/19.
//

import UIKit

class PredictionFollowUpViewController: WidgetController {
    var id: String
    var kind: WidgetKind
    
    weak var delegate: WidgetEvents?
    weak var eventsDelegate: EngagementEventsDelegate?
    var coreWidgetView: CoreWidgetView {
        return widgetView.coreWidgetView
    }
    
    var dismissSwipeableView: UIView {
        return self.view
    }

    private(set) lazy var widgetView: ChoiceWidgetView = {
        // build view
        let verticalChoiceWidget = VerticalChoiceWidget()
        verticalChoiceWidget.customize(predictionTheme, theme: theme)
        verticalChoiceWidget.titleView.titleLabel.text = theme.uppercaseTitleText ? widgetData.question.uppercased() : widgetData.question
        verticalChoiceWidget.titleView.titleMargins = theme.choiceWidgetTitleMargins
        var widgetOptionButtons = [ChoiceWidgetOptionButton]()

        switch type {
        case .image:
            widgetOptionButtons = widgetData.options.map { widgetOption in
                var widgetOptionButton = ChoiceWidgetOptionFactory().create(style: .wideTextImage, id: widgetOption.id)
                widgetOptionButton.customize(theme)
                widgetOptionButton.setText(widgetOption.text, theme: theme)
                if let url = widgetOption.imageUrl {
                    widgetOptionButton.setImage(url)
                }
                if let progress = widgetOption.progress {
                    widgetOptionButton.setProgress(CGFloat(progress))
                }
                highlightOptionView(widgetOptionButton: widgetOptionButton)
                return widgetOptionButton
            }
        case .text:
            widgetOptionButtons = widgetData.options.map { widgetOption in
                var widgetOptionButton: ChoiceWidgetOptionButton = ChoiceWidgetOptionFactory().create(style: .wideText, id: widgetOption.id)
                widgetOptionButton.customize(theme)
                widgetOptionButton.setText(widgetOption.text, theme: theme)
                if let progress = widgetOption.progress {
                    widgetOptionButton.setProgress(CGFloat(progress))
                }
                highlightOptionView(widgetOptionButton: widgetOptionButton)
                return widgetOptionButton
            }
        }

        verticalChoiceWidget.populateStackView(options: widgetOptionButtons)
        optionButtons = widgetOptionButtons
        return verticalChoiceWidget
    }()

    private let widgetData: ChoiceWidgetViewModel
    private let voteID: String
    private let predictionTheme: PredictionWidgetTheme
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private let type: ChoiceWidgetViewType
    private let correctOptionIds: [String]

    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var timeDisplayed = Date()

    private var optionButtons = [ChoiceWidgetOptionButton]()

    init(type: ChoiceWidgetViewType,
         widgetData: ChoiceWidgetViewModel,
         voteID: String,
         theme: Theme,
         kind: WidgetKind,
         correctOptionIds: [String],
         eventRecorder: EventRecorder,
         widgetConfig: WidgetConfig) {
        self.widgetData = widgetData
        id = widgetData.id
        self.voteID = voteID
        predictionTheme = theme.predictionWidget
        self.theme = theme
        self.type = type
        self.kind = kind
        self.correctOptionIds = correctOptionIds
        self.eventRecorder = eventRecorder
        self.widgetConfig = widgetConfig
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view.addSubview(widgetView)
        widgetView.constraintsFill(to: view)
        widgetView.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        if widgetConfig.isManualDismissButtonEnabled {
            widgetView.titleView.showCloseButton()
        }
        widgetView.titleView.beginTimer(duration: widgetData.timeout) { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
        }
    }

    @objc func closeButtonPressed() {
        delegate?.actionHandler(event: .dismiss(action: .tapX))
    }

    private func highlightOptionView(widgetOptionButton: ChoiceWidgetOptionButton) {
        let isCorrect = correctOptionIds.contains(widgetOptionButton.id)
        // highlight correct options
        if isCorrect {
            widgetOptionButton.setColors(theme.correctOptionColors)
            widgetOptionButton.layer.cornerRadius = theme.widgetCornerRadius
            return
        }
        
        // highlight incorrect option
        if !isCorrect {
            if widgetOptionButton.id == voteID {
                widgetOptionButton.setColors(theme.incorrectOptionColors)
                widgetOptionButton.layer.cornerRadius = theme.widgetCornerRadius
                return
            }
        }
        
        // otherwise highlight gray
        widgetOptionButton.setColors(theme.neutralOptionColors)
        widgetOptionButton.layer.cornerRadius = 0
    }

    func start() {
        let isCorrect = correctOptionIds.contains(voteID)
        if isCorrect {
            if let animationAsset = self.widgetData.animationCorrectAsset {
                widgetView.playOverlayAnimation(animationFilepath: animationAsset)
            }
        } else {
            if let animationAsset = self.widgetData.animationIncorrectAsset {
                widgetView.playOverlayAnimation(animationFilepath: animationAsset)
            }
        }
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: widgetData.id))
    }

    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            let properties = WidgetDismissedProperties(
                widgetId: widgetData.id,
                widgetKind: kind.analyticsName,
                dismissAction: dismissAction,
                numberOfTaps: 0,
                dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed)
            )
            eventRecorder.record(.widgetUserDismissed(properties: properties))
        }
    }
}
