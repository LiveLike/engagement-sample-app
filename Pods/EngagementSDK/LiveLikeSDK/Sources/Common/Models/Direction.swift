//
//  Direction.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-06.
//

import Foundation

/**
 Direction used for animating widgets in and out of the `WidgetViewController`.
 */
@objc
public enum Direction: Int {
    /// Left direction
    @objc(Left)
    case left = 0

    /// Right direction
    @objc(Right)
    case right

    /// Up direction
    @objc(Up)
    case up

    /// Down direction
    @objc(Down)
    case down
}
