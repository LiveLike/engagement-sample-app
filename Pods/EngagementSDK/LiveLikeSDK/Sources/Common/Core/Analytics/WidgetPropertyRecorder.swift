//
//  WidgetSuperPropertyRecorder.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/8/19.
//

import Foundation

/**
 Records the secondsSinceLastWidgetReceipt and secondsSinceLastWidgetInteraction
 When the widgetDisplay and widgetInteracted event is recorded respectively
 */
class WidgetPropertyRecorder {
    private var timeSinceLastWidgetDisplayedEvent: Date
    private var timeSinceLastWidgetInteractedEvent: Date
    private let superPropertyRecorder: SuperPropertyRecorder
    private let peoplePropertyRecorder: PeoplePropertyRecorder

    init(superPropertyRecorder: SuperPropertyRecorder, peoplePropertyRecorder: PeoplePropertyRecorder) {
        self.superPropertyRecorder = superPropertyRecorder
        self.peoplePropertyRecorder = peoplePropertyRecorder
        let now = Date()
        timeSinceLastWidgetDisplayedEvent = now
        timeSinceLastWidgetInteractedEvent = now

        superPropertyRecorder.register([.timeOfLastWidgetReceipt(time: timeSinceLastWidgetDisplayedEvent)])
        superPropertyRecorder.register([.timeOfLastWidgetInteraction(time: timeSinceLastWidgetInteractedEvent)])
        peoplePropertyRecorder.record([.timeOfLastWidgetReceipt(time: timeSinceLastWidgetDisplayedEvent)])
        peoplePropertyRecorder.record([.timeOfLastWidgetInteraction(time: timeSinceLastWidgetInteractedEvent)])
    }

    public func handleEvent(event: AnalyticsEvent) {
        switch event.name {
        case .widgetDisplayed:
            timeSinceLastWidgetDisplayedEvent = Date()
            superPropertyRecorder.register([.timeOfLastWidgetReceipt(time: timeSinceLastWidgetDisplayedEvent)])
            peoplePropertyRecorder.record([.timeOfLastWidgetReceipt(time: timeSinceLastWidgetDisplayedEvent)])
        case .widgetInteracted:
            timeSinceLastWidgetInteractedEvent = Date()
            superPropertyRecorder.register([.timeOfLastWidgetInteraction(time: timeSinceLastWidgetInteractedEvent)])
            peoplePropertyRecorder.record([.timeOfLastWidgetInteraction(time: timeSinceLastWidgetInteractedEvent)])
        default:
            break
        }
    }
}
