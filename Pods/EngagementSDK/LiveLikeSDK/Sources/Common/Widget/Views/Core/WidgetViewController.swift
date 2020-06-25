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
public class WidgetViewController: UIViewController {
    // MARK: Properties

    /// A `ContentSession` used by the WidgetController to link with the program on the CMS.
    public weak var session: ContentSession? {
        didSet {
            clearDisplayedWidget()
            session?.delegate = self
        }
    }
    
    private var widgetsToDisplayQueue: Queue<Widget> = Queue()
    /// A container view for handling animations and swipe gesture
    private let widgetContainer: UIView = UIView()
    private var widgetContainerXConstraint: NSLayoutConstraint!
    private var widgetContainerTopAnchorConstraint: NSLayoutConstraint!
    private var swipeGesture: UISwipeGestureRecognizer?
    private var theme: Theme = .dark
    private var displayedWidget: Widget?
    private lazy var widgetStateController: DefaultWidgetStateController = {
        return DefaultWidgetStateController(
            closeButtonAction: { [weak self] in
                self?.dismissWidget(direction: .up, dismissAction: .tapX)
            },
            widgetFinishedCompletion: { [weak self] in
                self?.dismissWidget(direction: .up, dismissAction: .complete)
            })
    }()

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
        session.rankClient?.getUserRank()
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
        displayedWidget?.view.removeFromSuperview()
        displayedWidget?.removeFromParent()
        displayedWidget = nil
    }
    
    private func dismissWidget(direction: Direction, dismissAction: DismissAction) {
        animateOut(
            direction: direction,
            completion: {
                self.clearDisplayedWidget()
                // immediately show next widget if any in queue
                self.showNextWidgetInQueue()
            }
        )
    }
    
    private func showNextWidgetInQueue() {
        guard let session = session as? InternalContentSession else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if
                self.displayedWidget == nil,
                let nextWidget = self.widgetsToDisplayQueue.dequeue()
            {
                // Don't show follow up widgets if there is no vote
                if nextWidget.kind == .textPredictionFollowUp || nextWidget.kind == .imagePredictionFollowUp {
                    if session.widgetVotes.findVote(for: nextWidget.id) == nil {
                        log.info("Not showing follow up prediction because no vote found.")
                        self.showNextWidgetInQueue() // recursive
                        return
                    }
                }
                
                self.clearDisplayedWidget()
                self.displayedWidget = nextWidget
                
                nextWidget.view.translatesAutoresizingMaskIntoConstraints = false
                self.addChild(nextWidget)
                self.widgetContainer.addSubview(nextWidget.view)
                nextWidget.didMove(toParent: self)
                
                nextWidget.view.constraintsFill(to: self.widgetContainer)
                
                self.animateIn { [weak self] in
                    guard let self = self else { return }
                    nextWidget.delegate = self.widgetStateController
                    nextWidget.moveToNextState()
                    self.addSwipeToDismissGesture(to: nextWidget.dismissSwipeableView)
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
    
    public func widget(_ session: ContentSession, didBecomeReady widget: Widget) {
        self.widgetsToDisplayQueue.enqueue(element: widget)
        self.showNextWidgetInQueue()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension WidgetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
