//
//  EngagementEvents.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-15.
//

import Foundation

protocol EngagementEventsDelegate: AnyObject {
    func engagementEvent(_ event: EngagementEvent)
}

enum EngagementEvent {
    case willDisplayWidget
    case didDisplayWidget
    case willDismissWidget
    case didDismissWidget
    case willHideWidget
    case didHideWidget
}
