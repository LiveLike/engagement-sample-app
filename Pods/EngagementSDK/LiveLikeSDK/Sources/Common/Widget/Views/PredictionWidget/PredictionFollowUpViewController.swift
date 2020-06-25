//
//  PredictionFollowUpViewController.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/22/19.
//

import UIKit

class PredictionFollowUpViewController: WidgetController {
    var widgetTitle: String?
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
                break
            case .results:
                enterResultsState()
            case .finished:
                enterFinishedState()
            }
        }
    }
    var id: String
    var kind: WidgetKind
    var interactionTimeInterval: TimeInterval?
    
    weak var delegate: WidgetEvents?
    var coreWidgetView: CoreWidgetView {
        return widgetView.coreWidgetView
    }
    
    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
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
    private let voteID: String?
    private let predictionTheme: PredictionWidgetTheme
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private let type: ChoiceWidgetViewType
    private let correctOptionIds: [String]
    private var closeButtonAction: (() -> Void)?

    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var timeDisplayed = Date()

    private var optionButtons = [ChoiceWidgetOptionButton]()

    init(type: ChoiceWidgetViewType,
         widgetData: ChoiceWidgetViewModel,
         voteID: String?,
         theme: Theme,
         kind: WidgetKind,
         correctOptionIds: [String],
         eventRecorder: EventRecorder,
         widgetConfig: WidgetConfig,
         title: String = "",
         options: Set<WidgetOption> = Set()
    ) {
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
        self.widgetTitle = title
        self.options = options
        self.interactionTimeInterval = widgetData.timeout
        self.customData = widgetData.customData
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
    }

    @objc func closeButtonPressed() {
        closeButtonAction?()
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
    
    func moveToNextState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.currentState {
            case .ready:
                self.currentState = .results
            case .interacting:
                break
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
        widgetView.titleView.showCloseButton()
    }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) { }

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
    
    private func enterResultsState() {
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
        widgetId: widgetData.id))
        if let voteID = voteID {
            let isCorrect = correctOptionIds.contains(voteID)
            let animationAsset = isCorrect ?
                theme.randomCorrectAnimationAsset() :
                theme.randomIncorrectAnimationAsset()
            widgetView.playOverlayAnimation(animationFilepath: animationAsset) { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        } else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
        }
    }
    
    private func enterFinishedState() {
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}
