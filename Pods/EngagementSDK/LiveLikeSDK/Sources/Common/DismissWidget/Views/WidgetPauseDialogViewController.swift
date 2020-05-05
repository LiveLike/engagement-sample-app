//
//  WidgetPauseDialogViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/5/19.
//

import UIKit

class WidgetPauseDialogViewController: WidgetController {
    
    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var customData: String?

    var id: String = ""
    var kind = WidgetKind.dismissToggle
    var interactionTimeInterval: TimeInterval? = nil

    weak var delegate: WidgetEvents?

    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }
    
    var coreWidgetView: CoreWidgetView {
        return dismissWidgetView.coreWidgetView
    }

    var dismissSwipeableView: UIView {
        return self.view
    }

    private var dismissWidgetView: DialogWidgetView = {
        let view = DialogWidgetView(lottieAnimationName: "emoji-stunning")
        return view
    }()

    private let widgetPauser: WidgetPauser
    private let widgetCrossSessionPauser: WidgetCrossSessionPauser
    private let theme: Theme
    private let eventRecorder: EventRecorder
    private let trigger: Trigger
    private var shouldPause: Bool = false
    private var shouldPauseForver: Bool = false

    init(widgetPauser: WidgetPauser, widgetCrossSessionPauser: WidgetCrossSessionPauser, eventRecorder: EventRecorder, theme: Theme, triggeredBy trigger: Trigger) {
        self.widgetPauser = widgetPauser
        self.widgetCrossSessionPauser = widgetCrossSessionPauser
        self.theme = theme
        self.trigger = trigger
        self.eventRecorder = eventRecorder
        self.widgetTitle = "Pause Widget"
        super.init(nibName: nil, bundle: nil)
        view.addSubview(dismissWidgetView)
        dismissWidgetView.constraintsFill(to: view)
        configureButtons()
        dismissWidgetView.customize(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    func start() {
        dismissWidgetView.playEmojiAnimation()
        delay(10, closure: { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
        })
    }

    func willDismiss(dismissAction: DismissAction) {
        if shouldPause {
            widgetPauser.pauseWidgets()
        }
        if shouldPauseForver {
            widgetCrossSessionPauser.pauseWidgetsForAllContentSessions()
        }
    }

    private func configureButtons() {
        dismissWidgetView.title.setWidgetSecondaryText("EngagementSDK.widget.DismissWidget.title".localized(withComment: "Title copy of DismissWidget").uppercased(), theme: theme)
        let noButtonTitle = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.responses.no".localized(withComment: "Option button text to cancel pausing widgets"), font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing)
        dismissWidgetView.noButton.setAttributedTitle(noButtonTitle, for: .normal)
        dismissWidgetView.noButton.addTarget(self, action: #selector(noButtonSelected), for: .touchUpInside)

        let forNowButtonTitle = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.responses.for-now".localized(withComment: "Option button text for pausing widgets for session duration"), font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing)
        dismissWidgetView.forNowButton.setAttributedTitle(forNowButtonTitle, for: .normal)
        dismissWidgetView.forNowButton.addTarget(self, action: #selector(forNowButtonSelected), for: .touchUpInside)

        let foreverButtonTitle = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.responses.forever".localized(withComment: "Option button text for pausing widgets forever"), font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing)
        dismissWidgetView.foreverButton.setAttributedTitle(foreverButtonTitle, for: .normal)
        dismissWidgetView.foreverButton.addTarget(self, action: #selector(foreverButtonSelected), for: .touchUpInside)
    }

    @objc private func noButtonSelected() {
        showConfirmation(text: "EngagementSDK.widget.DismissWidget.pause.confirmation.no".localized(withComment: "Confirmation text for not pausing widgets"), animation: "emoji-happy") { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .tapX))
        }

        eventRecorder.record(.widgetToggleActionSelected(selectedAction: .no, trigger: trigger))
    }

    /**
     Pause until end of session.
     Since plugins exist per session, when this plugin is reinstalled on a new session, widgets will
     be unpaused.
     */
    @objc private func forNowButtonSelected() {
        shouldPause = true
        showConfirmation(text: "EngagementSDK.widget.DismissWidget.pause.confirmation.for-now".localized(withComment: "Confirmation text for pausing widgets for rest of session"), animation: "emoji-devil") { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .tapX))
        }

        eventRecorder.record(.widgetToggleActionSelected(selectedAction: .forNow, trigger: trigger))
    }

    /**
     Pause widgets until resumeWidgets() is called.
     */
    @objc private func foreverButtonSelected() {
        shouldPauseForver = true
        showConfirmation(text: "EngagementSDK.widget.DismissWidget.pause.confirmation.forever".localized(withComment: "Confirmation text for pausing widgets forever"), animation: "emoji-cool") { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .tapX))
        }

        eventRecorder.record(.widgetToggleActionSelected(selectedAction: .forever, trigger: trigger))
    }

    private func showConfirmation(text: String, animation: String, completion: @escaping () -> Void) {
        let confirmationView = ActionConfirmationView(title: text, animationID: animation, duration: 5.0) {
            completion()
        }
        confirmationView.customize(theme: theme)
        view.addSubview(confirmationView)
        confirmationView.constraintsFill(to: dismissWidgetView.body)
        dismissWidgetView.alpha = 0.2
    }
}

extension WidgetPauseDialogViewController {
    enum Trigger {
        case togglePressed
        case passThreshold(threshold: Int)
    }
}

extension DialogWidgetView {
    func customize(theme: Theme) {
        coreWidgetView.baseView.clipsToBounds = true
        coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        body.backgroundColor = theme.widgetBodyColor

        noButton.livelike_cornerRadius = theme.widgetCornerRadius / 2
        noButton.gradient.livelike_startColor = UIColor(red: 105, green: 40, blue: 180)
        noButton.gradient.livelike_endColor = UIColor(red: 75, green: 40, blue: 180)

        forNowButton.livelike_cornerRadius = theme.widgetCornerRadius / 2
        forNowButton.gradient.livelike_startColor = UIColor(red: 240, green: 160, blue: 0)
        forNowButton.gradient.livelike_endColor = UIColor(red: 255, green: 130, blue: 0)

        foreverButton.livelike_cornerRadius = theme.widgetCornerRadius / 2
        foreverButton.gradient.livelike_startColor = UIColor(red: 86, green: 86, blue: 86)
        foreverButton.gradient.livelike_endColor = UIColor(red: 52, green: 52, blue: 52)
    }
}

extension WidgetPauseDialogViewController {
    class Factory {
        private let widgetPauser: WidgetPauser
        private let widgetCrossSessionPauser: WidgetCrossSessionPauser
        private let eventRecorder: EventRecorder

        init(widgetPauser: WidgetPauser, widgetCrossSessionPauser: WidgetCrossSessionPauser, eventRecorder: EventRecorder) {
            self.widgetPauser = widgetPauser
            self.widgetCrossSessionPauser = widgetCrossSessionPauser
            self.eventRecorder = eventRecorder
        }

        func create(theme: Theme, trigger: Trigger) -> WidgetPauseDialogViewController {
            return WidgetPauseDialogViewController(widgetPauser: widgetPauser, widgetCrossSessionPauser: widgetCrossSessionPauser, eventRecorder: eventRecorder, theme: theme, triggeredBy: trigger)
        }
    }
}

class GradientButton: UIButton {
    var gradient = GradientView(orientation: .horizontal)

    init() {
        super.init(frame: .zero)
        insertSubview(gradient, at: 0)
        clipsToBounds = true
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.constraintsFill(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
