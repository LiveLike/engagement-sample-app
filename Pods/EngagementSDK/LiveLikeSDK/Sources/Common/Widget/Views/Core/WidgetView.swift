//
//  WidgetView.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-31.
//

import UIKit

@objc(LLWidgetViewModel)
public protocol WidgetViewModel {
    var id: String { get }
    var kind: WidgetKind { get }
    var height: CGFloat { get }
}

protocol InternalWidgetViewModel {
    var id: String { get }
    var kind: WidgetKind { get }
    var delegate: WidgetEvents? { get set }
    var coreWidgetView: CoreWidgetView { get }
    var dismissSwipeableView: UIView { get }
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
    
    init(from internalWidgetViewModel: InternalWidgetViewModel) {
        id = internalWidgetViewModel.id
        kind = internalWidgetViewModel.kind
        height = internalWidgetViewModel.coreWidgetView.bounds.height + 32
    }
}

typealias WidgetView = UIView
typealias WidgetController = UIViewController & InternalWidgetViewModel
