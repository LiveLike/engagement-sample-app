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
    var interactionTimeInterval: TimeInterval?
    weak var delegate: WidgetEvents?
    var dismissSwipeableView: UIView {
        return self.view
    }

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
                enterInteractingState()
            case .results:
                break
            case .finished:
                enterFinishedState()
            }
        }
    }

    // MARK: Private Properties

    private lazy var alertWidget: AlertWidget = {
        let widget = AlertWidget(type: self.type)
        widget.translatesAutoresizingMaskIntoConstraints = false
        return widget
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
        self.widgetTitle = widgetData.title
        self.customData = widgetData.customData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCommonView()
        setupView(for: type)
        view.addSubview(alertWidget)
        alertWidget.constraintsFill(to: view)
        addGestures(to: alertWidget.coreWidgetView)
        alertWidget.isUserInteractionEnabled = false
    }

    func moveToNextState() {
        DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
            switch self.currentState {
            case .ready:
                self.currentState = .interacting
            case .interacting:
                self.currentState = .finished
            case .results:
                break
            case .finished:
                break
            }
        }
    }
    
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) { }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        delay(widgetData.timeout.timeInterval) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }
    
    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            let properties = WidgetDismissedProperties(widgetId: widgetData.id,
                                                       widgetKind: kind.stringValue,
                                                       dismissAction: dismissAction,
                                                       numberOfTaps: 0,
                                                       dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed))
            eventRecorder.record(.widgetUserDismissed(properties: properties))
            currentState = .finished
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
        alertWidget.contentView.imageView.setImage(url: url)
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
    
    // MARK: Handle States
    private func enterInteractingState() {
        alertWidget.isUserInteractionEnabled = true
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
        eventRecorder.record(.widgetDisplayed(kind: kind.stringValue, widgetId: widgetData.id))
    }
    
    private func enterFinishedState() {
        alertWidget.isUserInteractionEnabled = false
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}

// MARK: - Gestures

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
