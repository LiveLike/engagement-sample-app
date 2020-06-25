//
//  WidgetEvents.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-12.
//

import Foundation
typealias MetaData = [String: String]

public protocol WidgetEvents: AnyObject {
    func widgetDidEnterState(widget: WidgetViewModel, state: WidgetState)
    func widgetStateCanComplete(widget: WidgetViewModel, state: WidgetState)
}
