//
//  UIView+AnimatePromise.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/26/19.
//

import UIKit

extension UIView {
    static func animate(duration: TimeInterval, animations: @escaping () -> Void) -> Promise<Bool> {
        let promise = Promise<Bool>()
        animate(withDuration: duration, animations: animations) { complete in
            promise.fulfill(complete)
        }
        return promise
    }

    static func animate(duration: TimeInterval, delay: TimeInterval, options: AnimationOptions, animations: @escaping () -> Void) -> Promise<Bool> {
        let promise = Promise<Bool>()
        animate(withDuration: duration, delay: delay, options: options, animations: animations) { complete in
            promise.fulfill(complete)
        }
        return promise
    }

    static func animatePromise(withDuration: TimeInterval, delay: TimeInterval, usingSpringWithDamping: CGFloat, initialSpringVelocity: CGFloat, options: UIView.AnimationOptions, animations: @escaping () -> Void) -> Promise<Bool> {
        let promise = Promise<Bool>()
        animate(withDuration: withDuration,
                delay: delay,
                usingSpringWithDamping: usingSpringWithDamping,
                initialSpringVelocity: initialSpringVelocity,
                options: options,
                animations: animations) { complete in
            promise.fulfill(complete)
        }
        return promise
    }
}
