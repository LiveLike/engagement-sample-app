//
//  PubSubService.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/27/19.
//

import Foundation

/// Represents a publish/subscribe networking service
protocol PubSubService {
    func subscribe(_ channel: String) -> PubSubChannel
}
