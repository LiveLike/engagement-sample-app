//
//  WidgetViewController.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-01-11.
//  Copyright © 2019 Cory Sullivan. All rights reserved.
//

import PubNub
import UIKit

/// Delegate methods to the WidgetViewController
public protocol WidgetViewControllerDelegate: AnyObject {
    /// Called when a Widget is about to animate into the view
    func widgetViewController(_ widgetViewController: WidgetViewController, willDisplay widget: Widget)
    /// Called immediately after a Widget has finished animating into the view
    func widgetViewController(_ widgetViewController: WidgetViewController, didDisplay widget: Widget)
    /// Called when a Widget is about to animate out of the view
    func widgetViewController(_ widgetViewController: WidgetViewController, willDismiss widget: Widget)
    /// Called immediately after a Widget has finished animating out of the view
    func widgetViewController(_ widgetViewController: WidgetViewController, didDismiss widget: Widget)
    /// Called when the WidgetViewController receives a widget and will enqueue it to be displayed
    /// Return nil to not display the Widget
    func widgetViewController(_ widgetViewController: WidgetViewController, willEnqueueWidget widgetModel: WidgetModel) -> Widget?
}

public extension WidgetViewControllerDelegate {
    func widgetViewController(_ widgetViewController: WidgetViewController, willEnqueueWidget widgetModel: WidgetModel) -> Widget? {
        return DefaultWidgetFactory.makeWidget(from: widgetModel)
    }
}

/**
 A `WidgetViewController` instance represents a view controller that handles widgets for the `EngagementSDK`.

  Once an instance of `WidgetViewController` has been created, a `ContentSession` object needs to be set to link the `WidgetViewController` with the program/CMS. The 'ContentSession' can be changed at any time.

 The `WidgetViewController` can be presented as-is or placed inside a `UIView` as a child UIViewController. See [Apple Documentation](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW1) for more information.

 If the `WidgetViewController` is placed inside another view, please take note of the [minimum size restrictions](https://livelike.com). This restriction can be ignored by setting `ignoreSizeRestrictions`.

  Also, an extension was included for convenience to help add a view controller inside of a specificied view. Please see `UIViewController.addChild(viewController:view:)` for more information
 */
public class WidgetViewController: UIViewController {
    // MARK: Properties

    /// A `ContentSession` used by the WidgetController to link with the program on the CMS.
    public weak var session: ContentSession? {
        didSet {
            clearDisplayedWidget()
            session?.delegate = self
        }
    }

    /// The `Widget` currently displayed in the view (if any)
    public internal(set) var currentWidget: Widget?

    public weak var delegate: WidgetViewControllerDelegate?

    private var eventRecorder: EventRecorder? {
        return (session as? InternalContentSession)?.eventRecorder
    }
    
    private var widgetsToDisplayQueue: Queue<Widget> = Queue()
    /// A container view for handling animations and swipe gesture
    private let widgetContainer: UIView = UIView()
    private var widgetContainerXConstraint: NSLayoutConstraint!
    private var widgetContainerTopAnchorConstraint: NSLayoutConstraint!
    private var swipeGesture: UISwipeGestureRecognizer?
    private var theme: Theme = .dark
    private var timeWidgetDisplayed: Date?

    private var widgetStateController: DefaultWidgetStateController!

    // MARK: Init Functions

    public init(){
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// :nodoc:
    public override func loadView() {
        view = PassthroughView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        
        widgetStateController = DefaultWidgetStateController(
            closeButtonAction: { [weak self] in
                self?.dismissWidget(direction: .up, dismissAction: .tapX)
            },
            widgetFinishedCompletion: { [weak self] widget in
                guard let self = self else { return }
                guard widget.id == self.currentWidget?.id else { return }
                self.dismissWidget(direction: .up, dismissAction: .complete)
            }
        )
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        widgetContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(widgetContainer)

        widgetContainerTopAnchorConstraint = widgetContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        widgetContainerXConstraint = widgetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        NSLayoutConstraint.activate([
            widgetContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            widgetContainerXConstraint,
            widgetContainerTopAnchorConstraint
        ])
    }

    /// :nodoc:
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.clearDisplayedWidget()
    }

    // MARK: Customization

    /**
     Set the `Theme` for the `WidgetViewController`

     - parameter theme: A `Theme` object with values set to suit your product design.

     - note: A theme can be applied at any time and will update the view immediately
     */
    public func setTheme(_ theme: Theme) {
        self.theme = theme
        self.currentWidget?.theme = theme
        log.info("Theme was applied to the WidgetViewController")
    }

    // MARK: Public Methods

    /**
     Pauses the WidgetViewController.
     All future widgets will be discared until resume() is called.
     Any currently displayed widgets will be immediately dismissed.
     */
    public func pause() {
        guard let session = session as? InternalContentSession else {
            log.debug("Pause is not necessary when session is nil.")
            return
        }
        session.pauseWidgets()
        dismissWidget(direction: .up, dismissAction: .timeout)
    }

    /**
     Resumes the WidgetViewController.
     All future widgets will be received and rendered normally.
     */
    public func resume() {
        guard let session = session as? InternalContentSession else {
            log.debug("Resume not necessary when session is nil.")
            return
        }
        session.resumeWidgets()
    }

    private func addSwipeToDismissGesture(to view: UIView) {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        swipeGesture.delegate = self
        view.addGestureRecognizer(swipeGesture)
        self.swipeGesture = swipeGesture
    }

    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        dismissWidget(direction: .right, dismissAction: .swipe)
    }

    @objc func scrollViewDidChange(_ scrollView: UIScrollView) {
        swipeGesture?.isEnabled = scrollView.contentOffset.x <= 1.0
    }

    private func clearDisplayedWidget() {
        guard let displayedWidget = currentWidget else { return }

        displayedWidget.delegate = nil
        displayedWidget.view.removeFromSuperview()
        displayedWidget.removeFromParent()
        self.currentWidget = nil
        timeWidgetDisplayed = nil
        self.delegate?.widgetViewController(self, didDismiss: displayedWidget)
    }
    
    private func dismissWidget(direction: Direction, dismissAction: DismissAction) {
        guard let currentWidget = currentWidget else { return }
        self.delegate?.widgetViewController(self, willDismiss: currentWidget)

        animateOut(
            direction: direction,
            completion: { [weak self] in
                guard let self = self else { return }
                self.recordWidgetDismissedAnalytics(dismissAction: dismissAction)
                self.clearDisplayedWidget()
                // immediately show next widget if any in queue
                self.showNextWidgetInQueue()
            }
        )
    }

    private func recordWidgetDismissedAnalytics(dismissAction: DismissAction) {
        guard
            let eventRecorder = self.eventRecorder,
            let displayedWidget = self.currentWidget,
            let timeWidgetDisplayed = self.timeWidgetDisplayed
        else {
            return
        }

        if dismissAction.userDismissed {
            var properties = WidgetDismissedProperties(
                widgetId: displayedWidget.id,
                widgetKind: displayedWidget.kind.analyticsName,
                dismissAction: dismissAction,
                numberOfTaps: displayedWidget.interactionCount,
                dismissSecondsSinceStart: Date().timeIntervalSince(timeWidgetDisplayed)
            )
            if let lastTapTime = displayedWidget.timeOfLastInteraction {
                properties.dismissSecondsSinceLastTap = Date().timeIntervalSince(lastTapTime)
            }
            properties.interactableState = displayedWidget.interactableState
            eventRecorder.record(.widgetUserDismissed(properties: properties))
        }
    }
    
    private func showNextWidgetInQueue() {
        guard (session as? InternalContentSession) != nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if
                self.currentWidget == nil,
                let nextWidget = self.widgetsToDisplayQueue.dequeue()
            {
                self.clearDisplayedWidget()
                self.delegate?.widgetViewController(self, willDisplay: nextWidget)
                self.currentWidget = nextWidget
                
                nextWidget.view.translatesAutoresizingMaskIntoConstraints = false
                self.addChild(nextWidget)
                self.widgetContainer.addSubview(nextWidget.view)
                nextWidget.didMove(toParent: self)
                
                nextWidget.view.constraintsFill(to: self.widgetContainer)
                nextWidget.theme = self.theme
                
                // Determine if a widget contains a link to be used for analytics
                var widgetLink: URL?
                if let internalWidgetLink = nextWidget.widgetLink {
                    widgetLink = internalWidgetLink
                }
                
                self.animateIn { [weak self] in
                    guard let self = self else { return }
                    nextWidget.delegate = self.widgetStateController
                    nextWidget.moveToNextState()
                    self.addSwipeToDismissGesture(to: nextWidget.dismissSwipeableView)
                    self.eventRecorder?.record(
                        .widgetDisplayed(kind: nextWidget.kind.analyticsName, widgetId: nextWidget.id, widgetLink: widgetLink)
                    )
                    self.timeWidgetDisplayed = Date()
                    self.delegate?.widgetViewController(self, didDisplay: nextWidget)
                }
            }
        }
        
    }
    
    private func animateIn(completion: (() -> Void)? = nil) {
        widgetContainerTopAnchorConstraint.constant = -widgetContainer.bounds.height
        widgetContainerXConstraint.constant = 0
        view.layoutIfNeeded()
        
        UIView.animate(
            withDuration: 0.98,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0,
            options: .curveEaseInOut,
            animations: {
                self.widgetContainerTopAnchorConstraint.constant = 16
                self.view.layoutIfNeeded()
            }, completion: { _ in
                if let completion = completion {
                    completion()
                }
            }
        )
    }

    private func animateOut(direction: Direction, completion: @escaping (() -> Void) = {}) {
        
        let constraint: NSLayoutConstraint
        let multiplier: Int
        let offset: CGFloat

        switch direction {
        case .up, .down:
            constraint = self.widgetContainerTopAnchorConstraint
            offset = widgetContainer.bounds.height
        case .left, .right:
            constraint = self.widgetContainerXConstraint
            offset = (view.bounds.width / 2) + widgetContainer.bounds.width
        }

        switch direction {
        case .right, .down:
            multiplier = 1
        case .up, .left:
            multiplier = -1
        }

        UIView.animate(
            withDuration: 0.33,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                constraint.constant = offset * CGFloat(multiplier)
                self.view.layoutIfNeeded()
            }, completion: { _ in
                
                completion()
            }
        )
    }

    /// Makes a widget from the delegate or from the DefaultWidgetFactory
    private func makeWidget(from widgetModel: WidgetModel) -> Widget? {
        if let delegate = delegate {
            return delegate.widgetViewController(self, willEnqueueWidget: widgetModel)
        } else {
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }
}

// MARK: - Content Session Delelgate

extension WidgetViewController: ContentSessionDelegate {
    public func playheadTimeSource(_ session: ContentSession) -> Date? {
        return nil
    }
    
    public func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        
    }
    
    public func session(_ session: ContentSession, didReceiveError error: Error) {
        
    }
    
    public func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {
        
    }
    
    public func widget(_ session: ContentSession, didBecomeReady jsonObject: Any) { }
    
    public func widget(_ session: ContentSession, didBecomeReady widget: Widget) { }

    public func contentSession(_ session: ContentSession, didReceiveWidget widgetModel: WidgetModel) {
        if case let WidgetModel.predictionFollowUp(predictionFollowUpModel) = widgetModel {
            // Don't enqueue prediction follow up if there is no user vote
            predictionFollowUpModel.getVote { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    guard let widget = self.makeWidget(from: widgetModel) else { return }
                    self.widgetsToDisplayQueue.enqueue(element: widget)
                    self.showNextWidgetInQueue()
                case .failure:
                    return
                }
            }
        } else {
            guard let widget = self.makeWidget(from: widgetModel) else { return }
            self.widgetsToDisplayQueue.enqueue(element: widget)
            self.showNextWidgetInQueue()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension WidgetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
