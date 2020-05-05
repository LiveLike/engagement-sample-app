//
//  WidgetUnpauseDialogViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/10/19.
//

import UIKit

class WidgetUnpauseDialogViewController: WidgetController {
    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var id: String = ""
    var kind = WidgetKind.dismissToggle
    var interactionTimeInterval: TimeInterval? = nil
    var customData: String?

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
        let view = DialogWidgetView(lottieAnimationName: "emoji-hearteyes")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let widgetCrossSessionPauser: WidgetCrossSessionPauser
    private let theme: Theme
    private var shouldUnpause: Bool = false

    init(widgetCrossSessionPauser: WidgetCrossSessionPauser, theme: Theme) {
        self.widgetCrossSessionPauser = widgetCrossSessionPauser
        self.theme = theme
        self.widgetTitle = "Widget Pauser"
        super.init(nibName: nil, bundle: nil)
        configure()
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
        if shouldUnpause {
            widgetCrossSessionPauser.resumeWidgetsForAllContentSessions()
        }
    }

    private func configure() {
        dismissWidgetView.foreverButton.isHidden = true
        view.addSubview(dismissWidgetView)
        dismissWidgetView.constraintsFill(to: view)
    }

    private func configureButtons() {
        dismissWidgetView.title.setWidgetSecondaryText("EngagementSDK.widget.DismissWidget.unpause.title".localized(withComment: "Title text for unpausing widget through toggle").uppercased(), theme: theme)
        let noButtonTitle = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.unpause.responses.no".localized(withComment: "Cancel text for unpausing widget through toggle"), font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing)
        dismissWidgetView.noButton.setAttributedTitle(noButtonTitle, for: .normal)
        dismissWidgetView.noButton.addTarget(self, action: #selector(noButtonSelected), for: .touchUpInside)
        let yesButtonTitle = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.unpause.responses.yes".localized(withComment: "Confirm text for unpausing widget through toggle"), font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing)
        dismissWidgetView.forNowButton.setAttributedTitle(yesButtonTitle, for: .normal)
        dismissWidgetView.forNowButton.addTarget(self, action: #selector(yesButtonSelected), for: .touchUpInside)
    }

    @objc private func noButtonSelected() {
        showConfirmation(text: "EngagementSDK.widget.DismissWidget.unpause.confirmation.no".localized(withComment: "Confirmation text after cancel was selected in unpause widget flow"), animation: "emoji-cool") { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .tapX))
        }
    }

    @objc private func yesButtonSelected() {
        shouldUnpause = true
        showConfirmation(text: "EngagementSDK.widget.DismissWidget.unpause.confirmation.yes".localized(withComment: "Confirmation text after confirm was selected in unpause widget flow"), animation: "emoji-happy") { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .tapX))
        }
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

extension WidgetUnpauseDialogViewController {
    class Factory {
        private let widgetCrossSessionPauser: WidgetCrossSessionPauser

        init(widgetCrossSessionPauser: WidgetCrossSessionPauser) {
            self.widgetCrossSessionPauser = widgetCrossSessionPauser
        }

        func create(theme: Theme) -> WidgetUnpauseDialogViewController {
            return WidgetUnpauseDialogViewController(widgetCrossSessionPauser: widgetCrossSessionPauser, theme: theme)
        }
    }
}
