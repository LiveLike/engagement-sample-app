//
//  WidgetEvents.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-12.
//

import Foundation
typealias MetaData = [String: String]

protocol WidgetEvents: AnyObject {
    func actionHandler(event: WidgetEvent)
    func widgetInteractionDidBegin(widget: WidgetViewModel)
    func widgetInteractionDidComplete(properties: WidgetInteractedProperties)
}

enum WidgetEvent {
    case dismiss(action: DismissAction)
}
