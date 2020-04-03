//
//  AlertWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-20.
//

import UIKit

class AlertWidgetViewController: WidgetController {
    // MARK: Internal Properties

    var id: String
    var kind: WidgetKind

    weak var delegate: WidgetEvents?
    var coreWidgetView: CoreWidgetView {
        return alertWidget.coreWidgetView
    }

    var dismissSwipeableView: UIView {
        return self.view
    }

    // MARK: Private Properties

    private lazy var alertWidget: AlertWidget = {
        AlertWidget(type: self.type)
    }()

    private lazy var type: AlertWidgetViewType = {
        if self.widgetData.text?.isEmpty == false, self.widgetData.imageUrl != nil {
            return .both
        } else if self.widgetData.text?.isEmpty == false {
            return .text
        } else {
            return .image
        }
    }()

    private let widgetData: AlertCreated
    private let theme: Theme

    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var timeDisplayed = Date()

    // MARK: Init

    init(widgetData: AlertCreated, theme: Theme, kind: WidgetKind, eventRecorder: EventRecorder) {
        id = widgetData.id
        self.widgetData = widgetData
        self.theme = theme
        self.kind = kind
        self.eventRecorder = eventRecorder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override func loadView() {
        super.loadView()
        setupCommonView()
        setupView(for: type)
        view.addSubview(alertWidget)
        alertWidget.constraintsFill(to: view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addGestures(to: alertWidget.coreWidgetView)
    }

    func start() {
        delay(widgetData.timeout.timeInterval, closure: { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
        })
        eventRecorder.record(.widgetDisplayed(kind: kind.stringValue, widgetId: widgetData.id))
    }

    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            let properties = WidgetDismissedProperties(widgetId: widgetData.id,
                                                       widgetKind: kind.stringValue,
                                                       dismissAction: dismissAction,
                                                       numberOfTaps: 0,
                                                       dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed))
            eventRecorder.record(.widgetUserDismissed(properties: properties))
        }
    }

    // MARK: View Helpers

    private func setupCommonView() {
        alertWidget.linkView.backgroundColor = theme.alertWidget.linkBackgroundColor
        alertWidget.coreWidgetView.layer.cornerRadius = theme.widgetCornerRadius
        alertWidget.coreWidgetView.clipsToBounds = true
        alertWidget.coreWidgetView.backgroundColor = theme.widgetBodyColor
    }

    private func setupView(for style: AlertWidgetViewType) {
        setupTitleView()
        setupLinkView()

        switch style {
        case .both:
            setupTextView()
            setupImageView()
        case .image:
            setupImageView()
        case .text:
            setupTextView()
        }
    }

    private func setupImageView() {
        guard let url = widgetData.imageUrl else { return }

        alertWidget.contentView.imageView.setImage(key: url.absoluteString)
    }

    private func setupTextView() {
        alertWidget.contentView.textLabel.text = widgetData.text
        alertWidget.contentView.textLabel.textColor = theme.widgetFontPrimaryColor
        alertWidget.contentView.textLabel.font = theme.fontPrimary
    }

    private func setupTitleView() {
        if let title = widgetData.title {
            alertWidget.titleView.titleLabel.text = theme.uppercaseTitleText ? title.uppercased() : title
            alertWidget.titleView.titleLabel.textColor = theme.widgetFontSecondaryColor
            alertWidget.titleView.titleLabel.font = theme.fontSecondary
            alertWidget.titleView.gradientView.livelike_cornerRadius = theme.widgetCornerRadius / 2
            alertWidget.titleView.gradientView.livelike_startColor = theme.alertWidget.titleGradientLeft
            alertWidget.titleView.gradientView.livelike_endColor = theme.alertWidget.titleGradientRight
        } else {
            alertWidget.titleView.isHidden = true
        }
    }

    private func setupLinkView() {
        if widgetData.linkLabel?.isEmpty == false {
            alertWidget.linkView.titleLabel.text = widgetData.linkLabel
            alertWidget.linkView.titleLabel.textColor = theme.widgetFontSecondaryColor
            alertWidget.linkView.titleLabel.font = theme.fontSecondary
        } else {
            alertWidget.coreWidgetView.footerView = nil
        }
    }
}

// MARK: Gestures

extension AlertWidgetViewController {
    private func addGestures(to view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(sender: UISwipeGestureRecognizer) {
        guard let url = widgetData.linkUrl else { return }
        UIApplication.shared.open(url)
    }
}

extension AlertWidgetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
