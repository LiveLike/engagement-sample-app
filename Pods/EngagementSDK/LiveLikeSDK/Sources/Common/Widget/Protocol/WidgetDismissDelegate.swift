//
//  WidgetDismissDelegate.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/6/19.
//

import Foundation

protocol WidgetRendererDelegate: AnyObject {
    func widgetWillStopRendering(widget: WidgetViewModel)
    func widgetDidStopRendering(widget: WidgetViewModel, dismissAction: DismissAction)
    func widgetDidStartRendering(widget: Widget)
}
