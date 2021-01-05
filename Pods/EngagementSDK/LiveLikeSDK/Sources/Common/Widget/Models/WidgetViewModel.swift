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
    
    /// The date and time the widget has been created
    var createdAt: Date { get }
    
    /// The date and time the widget has been published from the Producer Suite
    var publishedAt: Date? { get }
    
    /// The time interval for which the user is able to interact with the widget
    var interactionTimeInterval: TimeInterval? { get }
    
    /// A set of widget options if it has any.
    /// Some widgets like alert widgets do not have any options to display.
    var options: Set<WidgetOption>? { get }
    
    var customData: String? { get }
    var previousState: WidgetState? { get set }
    var currentState: WidgetState { get set }
    var delegate: WidgetViewDelegate? { get set }
    
    /// Has the user interacted with the widget
    var userDidInteract: Bool { get }
    
    var dismissSwipeableView: UIView { get }
    var theme: Theme { get set }

    func moveToNextState()
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void)
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void)
}

/// WidgetOption is a class which represents an option a widget can have
public class WidgetOption: Hashable {
    public let id: String
    let voteURL: URL?
    public let text: String?
    public let image: UIImage?
    var imageUrl: URL?
    public let isCorrect: Bool?
    var voteCount: Int?

    init(
        id: String,
        voteURL: URL?,
        text: String? = nil,
        image: UIImage? = nil,
        imageURL: URL? = nil,
        isCorrect: Bool? = nil,
        voteCount: Int? = nil
    ) {
        self.id = id
        self.voteURL = voteURL
        self.text = text
        self.image = image
        self.imageUrl = imageURL
        self.isCorrect = isCorrect
        self.voteCount = voteCount
    }

    public static func == (lhs: WidgetOption, rhs: WidgetOption) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

public enum WidgetState: CaseIterable {
    case ready
    case interacting
    case results
    case finished
}
