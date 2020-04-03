//
//  PassthroughView.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-03-13.
//

import UIKit

/// The `PassthroughView` is a UIView that is able to pass user interactions
/// into the UIView below it in a multilayered UIView scenario.
public class PassthroughView: UIView {
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in subviews {
            if !view.isHidden, view.alpha > 0, view.isUserInteractionEnabled, view.point(inside: convert(point, to: view), with: event) {
                return true
            }
        }

        return false
    }
}
