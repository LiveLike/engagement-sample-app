//
//  WidgetViewModel.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 3/11/20.
//

import UIKit

public protocol WidgetViewModel: AnyObject {
    var id: String { get }
    var kind: WidgetKind { get }
    var widgetTitle: String? { get }
    
    /// The time interval for which the user is able to interact with the widget
    var interactionTimeInterval: TimeInterval? { get }
    
    /// A set of widget options if it has any.
    /// Some widgets like alert widgets do not have any options to display.
    var options: Set<WidgetOption>? { get }
    
    var customData: String? { get }
    var previousState: WidgetState? { get set }
    var currentState: WidgetState { get set }
    var delegate: WidgetEvents? { get set }
    
    /// Has the user interacted with the widget
    var userDidInteract: Bool { get }
    
    
    var dismissSwipeableView: UIView { get }

    func moveToNextState()
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void)
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void)
}

/// WidgetOption is a class which represents an option a widget can have
@objc public class WidgetOption: NSObject {
    public let id: String
    public let text: String?
    public let image: UIImage?
    public let isCorrect: Bool?

    init(
        id: String,
        text: String? = nil,
        image: UIImage? = nil,
        isCorrect: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.image = image
        self.isCorrect = isCorrect
    }
}

public enum WidgetDismissReason {
    /// The user has dismissed the widget
    case userDismiss

    /// The `dismissWidget()` method was called on the WidgetViewController
    case apiDismiss

    /// The widget has expired
    case timeExpired
}

public enum WidgetState {
    case ready
    case interacting
    case results
    case finished
}
