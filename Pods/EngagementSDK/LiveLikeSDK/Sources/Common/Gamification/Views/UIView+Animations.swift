//
//  UIView+Animations.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/8/19.
//

import UIKit

extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CASpringAnimation(keyPath: "transform.rotation")
        rotateAnimation.damping = 8
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat.pi * 2
        rotateAnimation.duration = rotateAnimation.settlingDuration

        if let delegate: CAAnimationDelegate = completionDelegate as? CAAnimationDelegate {
            rotateAnimation.delegate = delegate
        }
        layer.add(rotateAnimation, forKey: nil)
    }
}
