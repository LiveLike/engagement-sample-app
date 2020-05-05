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
    var coreWidgetView: CoreWidgetView { get }
    var dismissSwipeableView: UIView { get }
    var widgetTitle: String? { get }
    var interactionTimeInterval: TimeInterval? { get }
    
    /// The set of options if any
    var options: Set<WidgetOption>? { get }
    var customData: String? { get }
    func start()
    func willDismiss(dismissAction: DismissAction)
}

extension InternalWidgetViewModel {
    var viewModelSnapshot: WidgetViewModelSnapshot { return .init(from: self) }
}

class WidgetViewModelSnapshot: WidgetViewModel {
    var id: String
    var kind: WidgetKind
    var height: CGFloat
    var widgetTitle: String?
    var interactionTimeInterval: TimeInterval?
    var options: Set<WidgetOption>?
    var customData: String?
    
    init(from internalWidgetViewModel: InternalWidgetViewModel) {
        id = internalWidgetViewModel.id
        kind = internalWidgetViewModel.kind
        height = internalWidgetViewModel.height
        widgetTitle = internalWidgetViewModel.widgetTitle
        interactionTimeInterval = internalWidgetViewModel.interactionTimeInterval ?? 0
        options = internalWidgetViewModel.options
        customData = internalWidgetViewModel.customData
    }
}

typealias WidgetView = UIView
typealias WidgetController = UIViewController & InternalWidgetViewModel
