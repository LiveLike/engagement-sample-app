//
//  WidgetViewController.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-01-11.
//  Copyright © 2019 Cory Sullivan. All rights reserved.
//

import PubNub
import UIKit

/**
 A `WidgetViewController` instance represents a view controller that handles widgets for the `EngagementSDK`.

  Once an instance of `WidgetViewController` has been created, a `ContentSession` object needs to be set to link the `WidgetViewController` with the program/CMS. The 'ContentSession' can be changed at any time.

 The `WidgetViewController` can be presented as-is or placed inside a `UIView` as a child UIViewController. See [Apple Documentation](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW1) for more information.

 If the `WidgetViewController` is placed inside another view, please take note of the [minimum size restrictions](https://livelike.com). This restriction can be ignored by setting `ignoreSizeRestrictions`.

  Also, an extension was included for convenience to help add a view controller inside of a specificied view. Please see `UIViewController.addChild(viewController:view:)` for more information
 */
@objc(LLWidgetViewController)
public class WidgetViewController: UIViewController {
    // MARK: Properties

    /// A `ContentSession` used by the WidgetController to link with the program on the CMS.
    @objc
    public weak var session: ContentSession? {
        didSet {
            if let session = sessionImpl {
                dismissWidget(direction: .up)
                session.whenWidgetQueue.then { widgetQueue in
                    widgetQueue.renderer = self
                }.catch {
                    log.error($0.localizedDescription)
                }
                eventRecorder = session.eventRecorder
            }
        }
    }

    /**
     A delegate which is informed when a widget will be and has been displayed or dismissed.
     Can also be used to control presentation discarding and deferral of specific widgets.
     */
    public weak var widgetPresentationDelegate: WidgetPresentationDelegate?

    var widgetRendererListeners: Listener<WidgetRendererDelegate> = Listener<WidgetRendererDelegate>()
    var widgetEventListeners: Listener<WidgetEvents> = Listener<WidgetEvents>()
    var isRendering: Bool {
        return presentedWidget != nil
    }

    /**
     A Boolean value indicating whether the recommend size restrictions
     for the `WidgetViewController` will be respected.

     The default value for this property is `false`. The recommended width for
     `WidgetViewController` is **260** points. Normally, if the `WidgetViewController`
     width does not exceed this value no widgets will be displayed and an
     error logged to the console. If this property is set to `true` all widgets
     will be displayed. However, the correctness of the layout is not supported.
     */
    @objc public var ignoreSizeRestrictions = false
    
    // MARK: Internal Properties

    weak var delegate: EngagementEventsDelegate?
    weak var presentedWidget: WidgetController?

    // MARK: Private Properties

    private var deferredWidgets = [WidgetController]()

    private var sessionImpl: InternalContentSession? {
        return session as? InternalContentSession
    }

    private var swipeGesture: UISwipeGestureRecognizer?
    private let minimumContainerWidth: CGFloat = 260
    private var currentContainerWidth: CGFloat = 0
    private var theme: Theme = .dark
    private var widgetVisibilityStatus: VisibilityStatus = .shown
    // false if there is no current widget
    private var isCurrentWidgetShowing: Bool = false

    var widgetConfig: WidgetConfig {
        guard let session = session as? InternalContentSession else { return .default }
        return session.config.widgetConfig
    }

    // Analytics Properties

    private var eventRecorder: EventRecorder?
    private var timeVisibilityChanged: Date = Date()

    // MARK: Init Functions

    @objc public init(){
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        if !widgetConfig.isWidgetDismissedOnViewDisappear {
            dismissWidget(direction: .up)
        }
        widgetRendererListeners.removeAll()
    }

    /// :nodoc:
    public override func loadView() {
        view = PassthroughView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
    }

    /// :nodoc:
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentContainerWidth = view.frame.width
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    /// :nodoc:
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if widgetConfig.isWidgetDismissedOnViewDisappear {
            dismissWidget(direction: .up)
        }
    }

    // MARK: Customization

    /**
     Set the `Theme` for the `WidgetViewController`

     - parameter theme: A `Theme` object with values set to suit your product design.

     - note: A theme can be applied at any time and will update the view immediately
     */
    @objc public func setTheme(_ theme: Theme) {
        self.theme = theme
        log.info("Theme was applied to the WidgetViewController")
    }

    // MARK: Public Methods

    /**
     Pauses the WidgetViewController.
     All future widgets will be discared until resume() is called.
     Any currently displayed widgets will be immediately dismissed.
     */
    @objc public func pause() {
        guard let session = session as? InternalContentSession else {
            log.debug("Pause is not necessary when session is nil.")
            return
        }
        session.pauseWidgets()
    }

    /**
     Resumes the WidgetViewController.
     All future widgets will be received and rendered normally.
     */
    @objc public func resume() {
        guard let session = session as? InternalContentSession else {
            log.debug("Resume not necessary when session is nil.")
            return
        }
        session.resumeWidgets()
        session.rankClient?.getUserRank()
    }

    /**
     Enables widgets to be shown.
     If there is a widget running in the background when called - the widget will animate back to the screen in its current state.
     */
    @objc public func show() {
        guard widgetVisibilityStatus == .hidden else {
            log.verbose("Widgets are already showing.")
            return
        }
        eventRecorder?.record(.widgetVisibilityStatusChanged(previousStatus: widgetVisibilityStatus, newStatus: .shown, secondsInPreviousStatus: Date().timeIntervalSince(timeVisibilityChanged)))
        widgetVisibilityStatus = .shown
        timeVisibilityChanged = Date()
        log.info("Widgets will be shown.")
        if let currentWidget = presentedWidget {
            delegate?.engagementEvent(.willDisplayWidget)
            animateIn(coreWidgetView: currentWidget.coreWidgetView) {
                self.delegate?.engagementEvent(.didDisplayWidget)
            }
        }
    }

    /**
     Stops widgets from appearing but they will still be received and run in the background.
     If a widget is currently showing when called - the widget will animate offscreen.

     If show() is called before a background widget expires, the user can still interact with the widget.
     */
    @objc public func hide() {
        guard widgetVisibilityStatus == .shown else {
            log.verbose("Widgets are already hidden.")
            return
        }
        eventRecorder?.record(.widgetVisibilityStatusChanged(previousStatus: widgetVisibilityStatus, newStatus: .hidden, secondsInPreviousStatus: Date().timeIntervalSince(timeVisibilityChanged)))
        widgetVisibilityStatus = .hidden
        timeVisibilityChanged = Date()
        log.info("Widgets will be hidden.")
        if let currentWidget = presentedWidget {
            delegate?.engagementEvent(.willHideWidget)
            animateOut(direction: .up, coreWidgetView: currentWidget.coreWidgetView) {
                self.delegate?.engagementEvent(.didHideWidget)
            }
        }
    }

    /// The next deferred widget which can be presented or discarded via calls to `presentDeferredWidget()` or `discardDeferredWidget()`
    public var nextDeferredWidget: WidgetViewModel? {
        return deferredWidgets.first?.viewModelSnapshot
    }

    /**
     Presents the first widget in the deferred widget queue.
     The deferred widget queue is populated when the `widgetPresentationDelegate` returns `.defer` from the `shouldPresent(widget:)` call.
     */
    @objc public func presentDeferredWidget() {
        guard let deferred = deferredWidgets.first else {
            log.debug("`presentDeferredWidget()` called when no widgets are in the deffered queue")
            return
        }
        deferredWidgets.removeFirst()
        presentWidget(deferred)
    }

    /**
     Discards the first widget in the deferred widget queue.
     The deferred widget queue is populated when the `widgetPresentationDelegate` returns `.defer` from the `shouldPresent(widget:)` call.
     */
    @objc public func discardDeferredWidget() {
        guard deferredWidgets.count > 0 else {
            log.debug("`dismissDeferredWidget()` called when no widgets are in the deffered queue")
            return
        }
        deferredWidgets.removeFirst()
    }

    func removeWidget() {
        presentedWidget = nil
        removeAllChildViewControllers()
    }

    private func addSwipeToDismissGesture(to view: UIView) {
        guard widgetConfig.isSwipeGestureEnabled else { return }
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
}

extension WidgetViewController: WidgetRenderer {
    
    func subscribe(widgetEventsDelegate delegate: WidgetEvents) {
        self.widgetEventListeners.addListener(delegate)
    }
    
    func unsubscribe(widgetEventsDelegate delegate: WidgetEvents) {
        self.widgetEventListeners.removeListener(delegate)
    }
    
    func subscribe(widgetRendererDelegate delegate: WidgetRendererDelegate) {
        self.widgetRendererListeners.addListener(delegate)
    }
    
    func unsubscribe(widgetRendererDelegate delegate: WidgetRendererDelegate) {
        self.widgetRendererListeners.removeListener(delegate)
    }
    
    func displayWidget(from widgetFactory: WidgetFactory) {
        guard let widget = widgetFactory.create(theme: self.theme, widgetConfig: self.widgetConfig) else { return }
        displayWidget(widget)
    }

    func displayWidget(handler: (Theme) -> WidgetController) {
        let widget = handler(theme)
        displayWidget(widget)
    }

    private func displayWidget(_ widget: WidgetController) {
        let presentationDecision = widgetPresentationDelegate?
            .shouldPresent(widget: widget.viewModelSnapshot)
            ?? .present

        switch presentationDecision {
        case .present:
            presentWidget(widget)

        case .discard:
            log.info("Delegate discarded widget presentation for kind: \(widget.kind)")

        case .defer:
            deferredWidgets.append(widget)
        }
    }

    private func presentWidget(_ widget: WidgetController) {
        removeWidget()
        if invalidContainerWidth() {
            discardWidget(widget)
            return
        }
        widget.coreWidgetView.isHidden = true // hide widget by default to be controlled by animation
        presentedWidget = widget
        presentedWidget?.delegate = self
        addChild(viewController: widget, into: view)
        addSwipeToDismissGesture(to: widget.dismissSwipeableView)

        widgetRendererListeners.publish { $0.widgetDidStartRendering(widget: widget) }

        switch widgetVisibilityStatus {
        case .shown:
            delegate?.engagementEvent(.willDisplayWidget)
            isCurrentWidgetShowing = true
            animateIn(coreWidgetView: widget.coreWidgetView,
                      beforeAnimating: {
                        widgetPresentationDelegate?.willPresent(widget: widget.viewModelSnapshot, in: view)
            },
                      completion: {
                        self.delegate?.engagementEvent(.didDisplayWidget)
                        self.widgetPresentationDelegate?.didPresent(widget: widget.viewModelSnapshot, in: self.view)
                        widget.start()
            })
        case .hidden:
            // Start the widget without showing it
            widget.start()
        }
    }

    // MARK: Widget Lifecycle

    /**
     Dismiss the widget curretly being displayed by the WidgetViewController.

     - parameter direction : A value indicating the direction to animate the widget off of the view.
     */
    @objc
    public func dismissWidget(direction: Direction) {
        dismissWidget(direction: direction, dismissAction: .integrator)
    }

    private func willDismissWidget(dismissAction: DismissAction){
        guard let currentWidget = presentedWidget else { return }
        delegate?.engagementEvent(.willDismissWidget)
        widgetRendererListeners.publish { $0.widgetWillStopRendering(widget: currentWidget.viewModelSnapshot) }
        currentWidget.willDismiss(dismissAction: dismissAction)
        widgetPresentationDelegate?.willDismiss(widget: currentWidget.viewModelSnapshot, in: currentWidget.view.superview!, reason: dismissAction.dismissReason)
    }

    private func dismissWidget(direction: Direction, dismissAction: DismissAction) {
        willDismissWidget(dismissAction: dismissAction)

        guard let currentWidget = presentedWidget else { return }
        isCurrentWidgetShowing = false
        animateOut(direction: direction, coreWidgetView: currentWidget.coreWidgetView, completion: {
            self.delegate?.engagementEvent(.didDismissWidget)
            self.widgetRendererListeners.publish { $0.widgetDidStopRendering(widget: currentWidget.viewModelSnapshot, dismissAction: dismissAction) }
            self.widgetPresentationDelegate?.didDismiss(widget: currentWidget.viewModelSnapshot, reason: dismissAction.dismissReason)
            self.removeWidget()
        })
    }
}

extension WidgetViewController: WidgetEvents {
    func actionHandler(event: WidgetEvent) {
        widgetEventListeners.publish { $0.actionHandler(event: event) }
        switch event {
        case let .dismiss(action):
            if widgetConfig.isAutoDismissEnabled == false {
                // Integrator has disabled the auto dismiss
                willDismissWidget(dismissAction: action)
                break
            } else {
                dismissWidget(direction: .up, dismissAction: action)
            }
        }
    }
    
    func widgetInteractionDidBegin(widget: WidgetViewModel) {
        widgetEventListeners.publish { $0.widgetInteractionDidBegin(widget: widget) }
        widgetPresentationDelegate?.didBeginInteraction(widget: widget)
    }

    func widgetInteractionDidComplete(properties: WidgetInteractedProperties) {
        widgetEventListeners.publish { $0.widgetInteractionDidComplete(properties: properties) }
        widgetPresentationDelegate?.didEndInteraction(widget: properties.widgetViewModel)
    }
}

private extension WidgetViewController {
    func invalidContainerWidth() -> Bool {
        if ignoreSizeRestrictions { return false }
        return currentContainerWidth < minimumContainerWidth
    }

    func discardWidget(_ widget: WidgetController) {
        let message =
            """
            \(widget.kind) widget could not be displayed.
            \(String(describing: type(of: self))) has a view width of \(currentContainerWidth).
            However it requires a width of \(minimumContainerWidth)
            """
        log.severe(message)
    }
}

extension WidgetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
