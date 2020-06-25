//
//  WidgetInteractedProperties.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/22/19.
//

import Foundation

public struct WidgetInteractedProperties {
    var widgetId: String
    var widgetKind: String
    var firstTapTime: Date?
    var lastTapTime: Date?
    var numberOfTaps: Int
    var interactionTimeInterval: TimeInterval?
    var widgetViewModel: WidgetViewModel
    
    // Gamification Properties
    var pointsEarned: Int = 0
    var badgeLevelEarned: Int?
    var badgeEarned: String?
    var pointsInCurrentlevel: Int?
    var pointsToNextLevel: Int?

    init(
        widgetId: String,
        widgetKind: String,
        firstTapTime: Date?,
        lastTapTime: Date?,
        numberOfTaps: Int,
        interactionTimeInterval: TimeInterval?,
        widgetViewModel: WidgetViewModel,
        previousState: WidgetState,
        currentState: WidgetState
    ) {
        self.widgetId = widgetId
        self.widgetKind = widgetKind
        self.firstTapTime = firstTapTime
        self.lastTapTime = lastTapTime
        self.numberOfTaps = numberOfTaps
        self.interactionTimeInterval = interactionTimeInterval
        self.widgetViewModel = widgetViewModel
    }
  
    init(widget: WidgetViewModel) {
        self.widgetId = widget.id
        self.widgetKind = widget.kind.stringValue
        self.numberOfTaps = 0
        self.widgetViewModel = widget
    }
}
