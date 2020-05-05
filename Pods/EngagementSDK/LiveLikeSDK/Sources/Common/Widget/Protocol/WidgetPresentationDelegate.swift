//
//  WidgetPresentationDelegate.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 8/2/19.
//

import Foundation
import UIKit

/**
 Represents the decision of a delegate to present, discard or defer a widget.
 */
@objc(LLWidgetPresentationDecision)
public enum WidgetPresentationDecision: Int {
    /// Immediately shows the widget
    case present
    /// Discards the widget altogether
    case discard
    /// Defers the widget, which can be discarded or presented at a later time via the `presentDeferredWidget()` and `discardDeferredWidget` calls on `WidgetViewController`
    case `defer`
}

public enum WidgetDismissReason {
    /// The user has dismissed the widget
    case userDismiss
    
    /// The `dismissWidget()` method was called on the WidgetViewController
    case apiDismiss

    /// The widget has expired
    case timeExpired
}

/**
 A delegate which is informed when a widget will be and has been displayed or dismissed.
 Can also be used to control presentation discarding and deferral of specific widgets.
 */
public protocol WidgetPresentationDelegate: AnyObject {
    /**
     Asks the delegate whether to present the widget represented by the given `WidgetViewModel`.

     - parameter widget: A ViewModel containing useful information regarding the widget that is ready for presentation.
     - returns: A decision on whether to immediately `present`, permanently `discard`, or `defer` the decision.
     */
    func shouldPresent(widget: WidgetViewModel) -> WidgetPresentationDecision

    /**
     Informs the delegate that a widget will be presented.

     - parameter widget: Information regarding the widget that will be presented
     - parameter view: The view the widget will be presented inside of
     */
    func willPresent(widget: WidgetViewModel, in view: UIView)

    /**
     Informs the delegate that a widget will be dismissed.

     - parameter widget: Information regarding the widget that will be dismissed
     */
    func willDismiss(widget: WidgetViewModel, in view: UIView, reason: WidgetDismissReason)

    /**
     Informs the delegate that a widget has been presented.

     - parameter widget: Information regarding the widget that was presented
     - parameter view: The view the widget was presented inside of
     */
    func didPresent(widget: WidgetViewModel, in view: UIView)

    /**
     Informs the delegate that a widget has been dismissed.

     - parameter widget: Information regarding the widget that was dismissed
     */
    func didDismiss(widget: WidgetViewModel, reason: WidgetDismissReason)
    
    /// Informs the delegate that the interaction has started for the widget
    /// - Parameter widget: The widget data
    func didBeginInteraction(widget: WidgetViewModel)
    
    /// Informs the delegate that the interaction has ended for the widget
    /// - Parameter widget: The widget data
    func didEndInteraction(widget: WidgetViewModel)
}
