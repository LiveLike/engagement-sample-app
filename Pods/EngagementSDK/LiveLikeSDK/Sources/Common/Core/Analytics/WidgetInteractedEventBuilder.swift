//
//  WidgetInteractedEventBuilder.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/14/19.
//

import Foundation

/**
 Keeps track of widgetInteractionProperties and wait to raise the widgetInteracted analytics event
 until Rewards raises whether the widget has recieved or has not recieved any awards
 If awards were recieved - update the appropriate widgetInteractedProperties fields with new data
 */
class WidgetInteractedEventBuilder {
    private let eventRecorder: EventRecorder
    private var pendingWidgetInteractedProperties: [String: WidgetInteractedProperties] = [:]

    init(eventRecorder: EventRecorder, widgetQueue: WidgetQueue, rewards: Rewards) {
        self.eventRecorder = eventRecorder
        widgetQueue.widgetEventListeners.addListener(self)
        rewards.addDelegate(self)
    }
}

extension WidgetInteractedEventBuilder: WidgetEvents {
    func actionHandler(event: WidgetEvent) {}
    func widgetInteractionDidBegin(widget: WidgetViewModel) {}

    func widgetInteractionDidComplete(properties: WidgetInteractedProperties) {
        pendingWidgetInteractedProperties[properties.widgetId] = properties
    }
}

extension WidgetInteractedEventBuilder: RewardsDelegate {
    func rewards(noAwardsForWidget widgetID: String) {
        guard let widgetInteractedProperties = pendingWidgetInteractedProperties[widgetID] else { return }
        eventRecorder.record(.widgetInteracted(properties: widgetInteractedProperties))
        pendingWidgetInteractedProperties.removeValue(forKey: widgetID)
    }

    func rewards(didReceiveAwards awards: Awards, awardsProfile: AwardsProfile, widgetID: String) {
        guard var widgetInteractedProperties = pendingWidgetInteractedProperties[widgetID] else { return }
        if let pointsEarned = awards.points {
            widgetInteractedProperties.pointsEarned = Int(pointsEarned)
        }
        if let badgeEarned = awards.badges {
            widgetInteractedProperties.badgeEarned = badgeEarned.id
            widgetInteractedProperties.badgeLevelEarned = badgeEarned.level
        }
        let currentBadgePointsToUnlock = awardsProfile.currentBadge?.pointsToUnlock ?? 0
        let pointsInCurrentLevel = awardsProfile.totalPoints - currentBadgePointsToUnlock
        widgetInteractedProperties.pointsInCurrentlevel = Int(pointsInCurrentLevel)
        if let nextBadge = awardsProfile.nextBadge {
            widgetInteractedProperties.pointsToNextLevel = Int(nextBadge.pointsToUnlock - currentBadgePointsToUnlock - pointsInCurrentLevel)
        }
        
        eventRecorder.record(.widgetInteracted(properties: widgetInteractedProperties))
        pendingWidgetInteractedProperties.removeValue(forKey: widgetID)
    }

    func rewards(didRecieveError error: Error) {}
}
