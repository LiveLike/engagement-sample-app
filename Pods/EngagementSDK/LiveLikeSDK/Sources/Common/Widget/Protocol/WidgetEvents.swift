//
//  WidgetEvents.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-12.
//

import Foundation
typealias MetaData = [String: String]

@available(*, deprecated, renamed: "WidgetViewDelegate")
public typealias WidgetEvents = WidgetViewDelegate

/// Methods for managing a Widget lifecyle and other events
public protocol WidgetViewDelegate: AnyObject {
    /// The widget entered a new WidgetState
    func widgetDidEnterState(widget: WidgetViewModel, state: WidgetState)
    
    /// The widget has completed all delayed processes of the WidgetState (i.e. animations, http requests, etc.)
    func widgetStateCanComplete(widget: WidgetViewModel, state: WidgetState)
    
    /// The current user has interacted with the widget
    func userDidInteract(_ widget: WidgetViewModel)
}
