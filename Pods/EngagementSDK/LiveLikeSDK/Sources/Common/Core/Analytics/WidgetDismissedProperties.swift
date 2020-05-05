//
//  WidgetDismissedProperties.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/22/19.
//

import Foundation

enum DismissAction: String {
    case swipe = "Swipe"
    case tapX = "Tap X"
    case timeout = "Timeout"
    // The integrator has manually called the WidgetViewController.dismissWidget
    case integrator = "Integrator"
    // The widget has been 'completed' (eg. confirmation button). This should not be counted as a user dismiss
    case complete = "Complete"

    // Returns whether the user triggered the dismiss
    var userDismissed: Bool {
        switch self {
        case .swipe:
            return true
        case .tapX:
            return true
        case .timeout:
            return false
        case .integrator:
            return false
        case .complete:
            return false
        }
    }
    
    /// Converts DismissAction to a WidgetDismissReason
    var dismissReason: WidgetDismissReason {
        switch self {
        case .swipe:
            return .userDismiss
        case .tapX:
            return .userDismiss
        case .timeout:
            return .timeExpired
        case .integrator:
            return .apiDismiss
        case .complete:
            return .timeExpired
        }
    }
}

enum InteractableState: String {
    case openToInteraction = "Open To Interaction"
    case closedToInteraction = "Closed To Interaction"
}

struct WidgetDismissedProperties {
    var widgetId: String
    var widgetKind: String
    var dismissAction: DismissAction
    var numberOfTaps: Int
    var dismissSecondsSinceStart: Double
    var interactableState: InteractableState?
    var dismissSecondsSinceLastTap: Double?

    init(widgetId: String, widgetKind: String, dismissAction: DismissAction, numberOfTaps: Int, dismissSecondsSinceStart: Double) {
        self.widgetId = widgetId
        self.widgetKind = widgetKind
        self.dismissAction = dismissAction
        self.numberOfTaps = numberOfTaps
        self.dismissSecondsSinceStart = dismissSecondsSinceStart
    }
}
