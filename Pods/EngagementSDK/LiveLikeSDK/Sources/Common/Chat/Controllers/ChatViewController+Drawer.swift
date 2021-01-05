//
//  ChatViewController+Animation.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-27.
//

import UIKit

extension ChatViewController {
    // MARK: Rotation Event

    /// :nodoc:
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.resetChatViewPosition()
        }
    }

    // MARK: Show/Hide Chat

    @available(*, deprecated, message: "We recommend implementing chat showing functionality on your app's view hierarchy")
    public func show() {
        guard chatVisibilityStatus == .hidden else {
            log.verbose("Chat is already showing.")
            return
        }

        eventRecorder?.record(.chatVisibilityStatusChanged(previousStatus: chatVisibilityStatus, newStatus: .shown, secondsInPreviousStatus: Date().timeIntervalSince(timeVisibilityChanged)))
        chatVisibilityStatus = .shown
        timeVisibilityChanged = Date()

        isOnScreen = true
        view.superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1.0
            self.updateChatConstraints(point: CGPoint.zero)
        }

        pauseTimer?.invalidate()
        pauseTimer = nil
    }

    @available(*, deprecated, message: "We recommend implementing chat hiding functionality on your app's view hierarchy")
    public func hide() {
        guard chatVisibilityStatus == .shown else {
            log.verbose("Chat is already hidden.")
            return
        }

        eventRecorder?.record(.chatVisibilityStatusChanged(previousStatus: chatVisibilityStatus, newStatus: .hidden, secondsInPreviousStatus: Date().timeIntervalSince(timeVisibilityChanged)))
        chatVisibilityStatus = .hidden
        timeVisibilityChanged = Date()

        pauseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.pause()
        }

        isOnScreen = false
        let newPos = offScreenPoint(out: true, direction: animationDirection)
        view.superview?.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 0.0
            self.updateChatConstraints(point: newPos)
        }
    }

    func offScreenPoint(out: Bool, direction: Direction) -> CGPoint {
        guard let window = UIApplication.shared.keyWindow?.subviews.last else {
            return CGPoint(x: 0, y: 0)
        }
        var newXPos = CGFloat(0)
        var newYPos = CGFloat(0)

        if out {
            switch direction {
            case .up:
                let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: 0), to: view)
                let newOrigin = CGPoint(x: convertToPointOnWindow.x - view.bounds.size.width, y: convertToPointOnWindow.y - view.bounds.size.height)
                newYPos = newOrigin.y

            case .down:
                let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: UIScreen.main.bounds.height), to: view)
                newYPos = convertToPointOnWindow.y

            case .left:
                let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: 0), to: view)
                let newOrigin = CGPoint(x: convertToPointOnWindow.x - view.bounds.size.width, y: convertToPointOnWindow.y - view.bounds.size.height)
                newXPos = newOrigin.x

            case .right:
                let convertToPointOnWindow = window.convert(CGPoint(x: UIScreen.main.bounds.width, y: 0), to: view)
                newXPos = convertToPointOnWindow.x
            }
        }
        return CGPoint(x: newXPos, y: newYPos)
    }

    func updateChatConstraints(point: CGPoint) {
        if let topConstraint = self.view.findConstraint(layoutAttribute: .top),
            let bottomConstraint = self.view.findConstraint(layoutAttribute: .bottom),
            let leftConstraint = self.view.findConstraint(layoutAttribute: .leading),
            let rightConstraint = self.view.findConstraint(layoutAttribute: .trailing) {
            topConstraint.constant = point.y
            bottomConstraint.constant = point.y
            leftConstraint.constant = point.x
            rightConstraint.constant = point.x
            view.superview?.layoutIfNeeded()
        }
    }

    func resetChatViewPosition() {
        if isOnScreen {
            return
        }
        updateChatConstraints(point: offScreenPoint(out: true, direction: animationDirection))
    }
}
