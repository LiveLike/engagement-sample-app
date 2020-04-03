//
//  WidgetToggleViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/7/19.
//

import UIKit

class WidgetToggleViewController: UIViewController {
    private let widgetPauser: WidgetPauser
    private let widgetRenderer: WidgetRenderer
    private let unmuteDialogFactory: WidgetUnpauseDialogViewController.Factory
    private let muteDialogFactory: WidgetPauseDialogViewController.Factory
    private let theme: Theme
    private let eventRecorder: EventRecorder

    private let unmuteWidgetsView = WidgetToggleView()
    private var topAnchorConstraint: NSLayoutConstraint?
    private var lastStatusShown: PauseStatus?

    private lazy var widgetOffAttributedString: NSAttributedString = {
        let tagAttributedString = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.widget".localized(), font: theme.fontSecondary, color: theme.widgetFontSecondaryColor, lineSpacing: theme.widgetFontSecondaryLineSpacing)
        tagAttributedString.append(NSMutableAttributedString(" \("EngagementSDK.widget.DismissWidget.off".localized())", font: theme.fontSecondary, color: .red, lineSpacing: theme.widgetFontSecondaryLineSpacing))
        return tagAttributedString
    }()

    private lazy var widgetOnAttributedString: NSAttributedString = {
        let tagAttributedString = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.widget".localized(), font: theme.fontSecondary, color: theme.widgetFontSecondaryColor, lineSpacing: theme.widgetFontSecondaryLineSpacing)
        tagAttributedString.append(NSMutableAttributedString(" \("EngagementSDK.widget.DismissWidget.on".localized())", font: theme.fontSecondary, color: .green, lineSpacing: theme.widgetFontSecondaryLineSpacing))
        return tagAttributedString
    }()

    init(widgetPauser: WidgetPauser, widgetRenderer: WidgetRenderer, unmuteDialogFactory: WidgetUnpauseDialogViewController.Factory, muteDialogFactory: WidgetPauseDialogViewController.Factory, theme: Theme, eventRecorder: EventRecorder) {
        self.widgetPauser = widgetPauser
        self.widgetRenderer = widgetRenderer
        self.unmuteDialogFactory = unmuteDialogFactory
        self.muteDialogFactory = muteDialogFactory
        self.eventRecorder = eventRecorder
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
        self.widgetPauser.setDelegate(self)
        self.widgetRenderer.subscribe(widgetRendererDelegate: self)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    deinit {
        self.widgetPauser.removeDelegate(self)
        self.widgetRenderer.subscribe(widgetRendererDelegate: self)
    }

    private func configure() {
        unmuteWidgetsView.tagBackground.alpha = 0
        unmuteWidgetsView.tagBackground.isUserInteractionEnabled = false
        unmuteWidgetsView.isHidden = true
        unmuteWidgetsView.toggleButton.addTarget(self, action: #selector(unmuteButtonPressed), for: .touchUpInside)
        unmuteWidgetsView.customize(theme)

        unmuteWidgetsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unmuteWidgetsView)
        topAnchorConstraint = unmuteWidgetsView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        NSLayoutConstraint.activate([
            topAnchorConstraint!,
            unmuteWidgetsView.widthAnchor.constraint(greaterThanOrEqualTo: unmuteWidgetsView.toggleButton.widthAnchor),
            unmuteWidgetsView.heightAnchor.constraint(greaterThanOrEqualTo: unmuteWidgetsView.toggleButton.heightAnchor),
            unmuteWidgetsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func configureTagAsOff() {
        unmuteWidgetsView.tagLabel.attributedText = widgetOffAttributedString
    }

    private func configureTagAsOn() {
        unmuteWidgetsView.tagLabel.attributedText = widgetOnAttributedString
    }

    @objc private func unmuteButtonPressed() {
        eventRecorder.record(.widgetToggleButtonPressed(pauseStatusWhenPressed: widgetPauser.widgetPauseStatus))

        switch widgetPauser.widgetPauseStatus {
        case .paused:
            widgetRenderer.displayWidget(handler: { theme in
                self.unmuteDialogFactory.create(theme: theme)
            })
        case .unpaused:
            widgetRenderer.displayWidget(handler: { theme in
                self.muteDialogFactory.create(theme: theme, trigger: .togglePressed)
            })
        }
    }

    func show() {
        guard let topAnchorConstraint = topAnchorConstraint else { return }
        unmuteWidgetsView.alpha = 0
        unmuteWidgetsView.isHidden = false
        topAnchorConstraint.constant = -unmuteWidgetsView.toggleButton.bounds.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.unmuteWidgetsView.alpha = 1
            topAnchorConstraint.constant = 16
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.flashTag()
        })
    }

    func hide() {
        guard let topAnchorConstraint = topAnchorConstraint else { return }
        unmuteWidgetsView.alpha = 1
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.unmuteWidgetsView.alpha = 0
            topAnchorConstraint.constant = -self.unmuteWidgetsView.toggleButton.bounds.height
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.unmuteWidgetsView.isHidden = true
        })
    }

    private func flashTag() {
        UIView.animate(withDuration: 0.2, animations: {
            self.unmuteWidgetsView.tagBackground.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 2, animations: {
                self.unmuteWidgetsView.tagBackground.alpha = 0
            })
        })
    }

    // We only want to show the unmute button while there is no widget showing (including the dismiss dialog
    private func updateTagVisibility(pauseStatus: PauseStatus, widgetIsShowing: Bool) {
        if lastStatusShown != pauseStatus, !widgetIsShowing {
            lastStatusShown = pauseStatus
            flashTag()
        }
    }

    private func updateWidgetToggleView(pauseStatus: PauseStatus) {
        switch pauseStatus {
        case .paused:
            configureTagAsOff()
            unmuteWidgetsView.showMuteButton()
        case .unpaused:
            configureTagAsOn()
            unmuteWidgetsView.showUnmuteButton()
        }
    }
}

// MARK: - Lifecycle Event

extension WidgetToggleViewController {
    override func loadView() {
        view = PassthroughView()
    }

    override func viewDidLoad() {
        configure()
        // initialize with current pause status
        updateWidgetToggleView(pauseStatus: widgetPauser.widgetPauseStatus)
    }
}

extension WidgetToggleView {
    func customize(_ theme: Theme) {
        tagBackground.livelike_cornerRadius = theme.widgetCornerRadius
        tagBackground.backgroundColor = theme.widgetBodyColor
    }
}

extension WidgetToggleViewController: PauseDelegate {
    func pauseStatusDidChange(status: PauseStatus) {
        updateWidgetToggleView(pauseStatus: status)
        updateTagVisibility(pauseStatus: status, widgetIsShowing: widgetRenderer.isRendering)
    }
}

extension WidgetToggleViewController: WidgetRendererDelegate {
    func widgetWillStopRendering(widget: WidgetViewModel) { }
    
    func widgetDidStartRendering(widget: WidgetController) {
        updateTagVisibility(pauseStatus: widgetPauser.widgetPauseStatus, widgetIsShowing: true)
    }

    func widgetDidStopRendering(widget: WidgetViewModel, dismissAction: DismissAction) {
        updateTagVisibility(pauseStatus: widgetPauser.widgetPauseStatus, widgetIsShowing: false)
    }
}
