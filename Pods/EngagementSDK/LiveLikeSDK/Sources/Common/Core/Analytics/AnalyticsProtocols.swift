//
//  AnalyticsProtocols.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import Foundation

protocol EventRecorder {
    func record(_ event: AnalyticsEvent)
}

protocol PeoplePropertyRecorder {
    func record(_ properties: [PeopleProperty])
    func recordOnce(_ properties: [PeopleProperty])
    func record(fromStringDict stringDict: [String: String])
    func increment(_ property: PeopleProperty, by amount: Double)
}

extension PeoplePropertyRecorder {
    func increment(_ property: PeopleProperty, by amount: Int = 1) {}
}

protocol SuperPropertyRecorder {
    func register(_ properties: [SuperProperty])
    func registerOnce(_ properties: [SuperProperty])
    func register(fromStringDict stringDict: [String: String])
}

protocol SuperPropertyCache {
    func getProperty(name: SuperProperty.Name) -> Any?
}

protocol AnalyticsProtocol: EventRecorder, SuperPropertyRecorder, PeoplePropertyRecorder {}

protocol IdentityRecorder {
    // Sets the distinct id of a user
    func identify(id: String)
    // This should only be called once per user (ie. when the user signs up)
    func alias(alias: String)
}

/**
 Delegate for receiving analytic events.
 */
@objc(LLAnalyticsDelegate)
public protocol EngagementAnalyticsDelegate {
    /**
     Called when an analytic event is recorded by the Engagement SDK.

     - parameter name: Name of event that has been recorded.
     - parameter data: Dictionary of data related to the event. The key will always be a string. The value can be either String, Int, UInt, Double, Float, Bool, Date, URL, Array.
     */
    func engagementAnalyticsEvent(name: String, withData data: [String: Any])
}
