//
//  UIViewController+DefaultWidgetAnimation.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/15/19.
//

import UIKit

extension WidgetViewController {
    func animateIn(coreWidgetView: CoreWidgetView, beforeAnimating: () -> Void = {}, completion: (() -> Void)? = nil) {
        coreWidgetView.isHidden = false
        guard let coreWidgetYConstraint = coreWidgetView.coreWidgetYConstraint else {
            if let completion = completion {
                completion()
            }
            return
        }

        guard widgetConfig.isWidgetAnimationsEnabled else {
            coreWidgetYConstraint.constant = 16
            self.view.layoutIfNeeded()
            completion?()
            return
        }

        coreWidgetYConstraint.constant = -((view.bounds.height / 2) + coreWidgetView.bounds.height)
        view.layoutIfNeeded()
        
        beforeAnimating()

        UIView.animate(withDuration: 0.98, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            coreWidgetYConstraint.constant = 16
            self.view.layoutIfNeeded()
        }, completion: { _ in
            if let completion = completion {
                completion()
            }
        })
    }

    func animateOut(direction: Direction, coreWidgetView: CoreWidgetView, completion: @escaping (() -> Void) = {}) {
        guard widgetConfig.isWidgetAnimationsEnabled else {
            completion()
            return
        }
        guard let coreWidgetYConstraint = coreWidgetView.coreWidgetYConstraint, let coreWidgetXConstraint = coreWidgetView.coreWidgetXConstraint else {
            completion()
            return
        }

        let constraint: NSLayoutConstraint
        let multiplier: Int
        let offset: CGFloat

        switch direction {
        case .up, .down:
            constraint = coreWidgetYConstraint
            offset = (view.bounds.height / 2) + coreWidgetView.bounds.height
        case .left, .right:
            constraint = coreWidgetXConstraint
            offset = (view.bounds.width / 2) + coreWidgetView.bounds.width
        }

        switch direction {
        case .right, .down:
            multiplier = 1
        case .up, .left:
            multiplier = -1
        }

        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut], animations: {
            constraint.constant = offset * CGFloat(multiplier)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            coreWidgetView.isHidden = true
            completion()
        })
    }
}
