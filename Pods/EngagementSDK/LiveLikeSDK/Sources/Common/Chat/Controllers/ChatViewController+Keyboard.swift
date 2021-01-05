//
//  ChatViewController+Keyboard.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-27.
//

import UIKit

extension ChatViewController {
    // MARK: Gestures

    @objc func didRecognizeTapGesture() {
        if chatInputView.textField.isFirstResponder {
            let keyboardProperties = KeyboardHiddenProperties(keyboardType: keyboardType, keyboardHideMethod: .resignedResponder, messageID: nil)
            eventRecorder?.record(.keyboardHidden(properties: keyboardProperties))
            dismissKeyboard()
        }
    }

    func addKeyboardDismissGesture() {
        tapGesture.delegate = self
        UIApplication.shared.keyWindow?.addGestureRecognizer(tapGesture)
    }

    func removeKeyboardDismissGesture() {
        tapGesture.delegate = nil
        UIApplication.shared.keyWindow?.removeGestureRecognizer(tapGesture)
    }

    /// Forces the dismissal of the chat keyboard
    @objc public func dismissKeyboard() {
        chatInputView.textField.resignFirstResponder()
        chatInputView.updateKeyboardType(.standard, isReset: true)
    }

    // MARK: Keyboard Notifications

    func addKeyboardNotifications() {
        let notification2Responder = [
            UIResponder.keyboardWillShowNotification: { [weak self] in
                self?.keyboardWillShow(notification: $0)
            },
            UIResponder.keyboardDidShowNotification: { [weak self] in
                self?.keyboardDidShow(notification: $0)
            },
            UIResponder.keyboardWillHideNotification: { [weak self] in
                self?.keyboardWillHide(notification: $0)
            },
            UIResponder.keyboardDidHideNotification: { [weak self] in
                self?.keyboardDidHide(notification: $0)
            }
        ]

        keyboardNotificationTokens = notification2Responder.map { keyValuePair in
            let (name, method) = keyValuePair
            return NotificationCenter.default.addObserver(forName: name,
                                                          object: nil,
                                                          queue: nil)
            { notification in
                method(notification)
            }
        }
    }

    private func keyboardWillShow(notification: Notification) {
        assert(Thread.isMainThread)

        if isRotating {
            return
        }

        doAnimations(forKeyboardNotification: notification)
        messageViewController.shouldScrollToNewestMessageOnArrival = true
        messageViewController.scrollToMostRecent(force: true, returnMethod: .keyboard)
    }

    private func keyboardDidShow(notification: Notification) {
        assert(Thread.isMainThread)

        if isRotating {
            return
        }

        // integrator completion handler for keyboardDidShow
        keyboardDidShowCompletion?()
    }

    private func keyboardWillHide(notification: Notification) {
        assert(Thread.isMainThread)

        if isRotating {
            return
        }

        doAnimations(forKeyboardNotification: notification)
        messageViewController.scrollToMostRecent(force: true, returnMethod: .keyboard)
    }

    private func keyboardDidHide(notification: Notification) {
        assert(Thread.isMainThread)

        if isRotating {
            return
        }

        // integrator completion handler for keyboardDidHide
        keyboardDidHideCompletion?()
    }

    private func doAnimations(forKeyboardNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardScreenFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }
        
        guard chatVisibilityStatus == .shown else {
            inputContainerBottomConstraint.constant = 0
            return
        }

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
            as? Double
            ?? 0.0
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int)
            .flatMap { UIView.AnimationCurve(rawValue: $0) }
            ?? UIView.AnimationCurve.easeInOut

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationBeginsFromCurrentState(true)

        let inputContainerViewKeyboardFrame = UIScreen.main.coordinateSpace
            .convert(keyboardScreenFrame, to: view)

        let overlapRect = inputContainerViewKeyboardFrame.intersection(view.bounds)
        var overlapHeight = !overlapRect.isNull ? overlapRect.height : 0.0
        if #available(iOS 11.0, *), overlapHeight >= view.safeAreaInsets.bottom {
            overlapHeight -= view.safeAreaInsets.bottom
        }

        inputContainerBottomConstraint.constant = overlapHeight
        view.setNeedsLayout()
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ChatViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        guard gestureRecognizer == tapGesture else {
            return false
        }

        let blacklist =
            (chatInputView.keyboardToggleButton.gestureRecognizers ?? [])
            + (chatInputView.textField.gestureRecognizers ?? [])

        return blacklist.contains(otherGestureRecognizer)
    }
}
