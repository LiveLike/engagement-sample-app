//
//  AlertWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-20.
//

import UIKit

class AlertWidgetViewController: Widget {

    // MARK: Internal Properties

    var correctOptions: Set<WidgetOption>?
    override var theme: Theme {
        didSet {
            self.applyTheme(theme)
        }
    }
    override var currentState: WidgetState {
        willSet {
            previousState = self.currentState
        }
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetDidEnterState(widget: self, state: self.currentState)
                switch self.currentState {
                case .ready:
                    break
                case .interacting:
                    self.enterInteractingState()
                case .results:
                    break
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }

    private var firstTapTime: Date?

    // MARK: Private Properties

    private lazy var alertWidget: AlertWidget = {
        let widget = AlertWidget(type: self.type)
        widget.translatesAutoresizingMaskIntoConstraints = false
        return widget
    }()

    private lazy var type: AlertWidgetViewType = {
        if self.model.text?.isEmpty == false, self.model.imageURL != nil {
            return .both
        } else if self.model.text?.isEmpty == false {
            return .text
        } else {
            return .image
        }
    }()

    // MARK: Analytics

    private let model: AlertWidgetModel

    // MARK: Init

    override init(
        model: AlertWidgetModel
    ) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCommonView()
        setupView(for: type)
        applyTheme(theme)
        view.addSubview(alertWidget)
        alertWidget.constraintsFill(to: view)
        addGestures(to: alertWidget.coreWidgetView)
        alertWidget.isUserInteractionEnabled = false

        model.registerImpression()
    }

    override func moveToNextState() {
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
    
    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) { }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        delay(model.interactionTimeInterval) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }

    // MARK: View Helpers
    
    private func applyTheme(_ theme: Theme) {
        alertWidget.applyContainerProperties(theme.widgets.alert.main)
        alertWidget.contentView.applyContainerProperties(theme.widgets.alert.body)
        alertWidget.contentView.textLabel.textColor = theme.widgets.alert.description.color
        alertWidget.contentView.textLabel.font = theme.widgets.alert.description.font
        alertWidget.titleView.applyContainerProperties(theme.widgets.alert.header)
        alertWidget.titleView.titleLabel.textColor = theme.widgets.alert.title.color
        alertWidget.titleView.titleLabel.font = theme.widgets.alert.title.font
        alertWidget.linkView.applyContainerProperties(theme.widgets.alert.footer)
        alertWidget.linkView.titleLabel.textColor = theme.widgets.alert.link.color
        alertWidget.linkView.titleLabel.font = theme.widgets.alert.link.font
    }

    private func setupCommonView() {
        alertWidget.coreWidgetView.clipsToBounds = true
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
        guard let url = model.imageURL else { return }
        alertWidget.contentView.imageView.setImage(url: url)
    }

    private func setupTextView() {
        alertWidget.contentView.textLabel.text = model.text
    }

    private func setupTitleView() {
        if let title = model.title {
            alertWidget.titleView.titleLabel.text = theme.uppercaseTitleText ? title.uppercased() : title
        } else {
            alertWidget.titleView.isHidden = true
        }
    }

    private func setupLinkView() {
        if model.linkLabel?.isEmpty == false {
            alertWidget.linkView.titleLabel.text = model.linkLabel
        } else {
            alertWidget.coreWidgetView.footerView = nil
        }
    }
    
    // MARK: Handle States
    private func enterInteractingState() {
        alertWidget.isUserInteractionEnabled = true
        self.interactableState = .openToInteraction
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterFinishedState() {
        if let firstTapTime = self.firstTapTime, let lastTapTime = self.timeOfLastInteraction {
            self.model.eventRecorder.record(
                .widgetInteracted(
                    properties: WidgetInteractedProperties(
                        widgetId: self.model.id,
                        widgetKind: self.model.kind.analyticsName,
                        firstTapTime: firstTapTime,
                        lastTapTime: lastTapTime,
                        numberOfTaps: self.interactionCount
                    )
                )
            )
        }
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
        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        timeOfLastInteraction = now
        interactionCount += 1

        model.openLinkUrl()
        self.delegate?.userDidInteract(self)
    }
}

extension AlertWidgetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
