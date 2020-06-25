//
//  WidgetView.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-31.
//

import UIKit

protocol InternalWidgetViewModel: WidgetViewModel {
    var id: String { get }
    var kind: WidgetKind { get }
    var delegate: WidgetEvents? { get set }
    var widgetTitle: String? { get }
    var interactionTimeInterval: TimeInterval? { get }
    
    /// The set of options if any
    var options: Set<WidgetOption>? { get }
    var customData: String? { get }
    func willDismiss(dismissAction: DismissAction)
}

typealias WidgetView = UIView
typealias WidgetController = UIViewController & InternalWidgetViewModel & WidgetViewModel

public typealias Widget = UIViewController & WidgetViewModel
