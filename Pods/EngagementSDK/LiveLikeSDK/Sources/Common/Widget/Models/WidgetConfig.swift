//
//  WidgetConfig.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/5/19.
//

import Foundation

/// A set of flags that modify the behavior of Widgets
@objc public class WidgetConfig: NSObject {
    /// :nodoc:
    public override init() {
        self.isAutoDismissEnabled = true
        self.isManualDismissButtonEnabled = true
        self.isSwipeGestureEnabled = true
        self.isWidgetAnimationsEnabled = true
        self.isWidgetDismissedOnViewDisappear = true
    }

    /// should the widget automatically be dismissed when completed. Default is true.
    @objc public var isAutoDismissEnabled: Bool
    /// should an dismiss button (X) be shown on some widgets when completed. Default is true.
    @objc public var isManualDismissButtonEnabled: Bool
    /// allow the user to dismiss widgets by swiping to the right. Default is true.
    @objc public var isSwipeGestureEnabled: Bool
    /// use the default animations for when a widget is received and dismissed. Default is true.
    @objc public var isWidgetAnimationsEnabled: Bool
    /// should the widget be dismissed when the `WidgetViewController` calls `viewWillDisappear`. Default is true.
    @objc public var isWidgetDismissedOnViewDisappear: Bool

    static let `default`: WidgetConfig = WidgetConfig()
}
