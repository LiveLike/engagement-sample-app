//
//  WidgetInteractedProperties.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/22/19.
//

import Foundation

struct WidgetInteractedProperties {
    var widgetId: String
    var widgetKind: String
    var firstTapTime: Date
    var lastTapTime: Date
    var numberOfTaps: Int
    
    // Gamification Properties
    var pointsEarned: Int = 0
    var badgeLevelEarned: Int?
    var badgeEarned: String?
    var pointsInCurrentlevel: Int?
    var pointsToNextLevel: Int?

    init(widgetId: String, widgetKind: String, firstTapTime: Date, lastTapTime: Date, numberOfTaps: Int) {
        self.widgetId = widgetId
        self.widgetKind = widgetKind
        self.firstTapTime = firstTapTime
        self.lastTapTime = lastTapTime
        self.numberOfTaps = numberOfTaps
    }
}
