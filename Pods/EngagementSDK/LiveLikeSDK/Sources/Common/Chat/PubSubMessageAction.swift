//
//  PubSubMessageAction.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

struct PubSubMessageAction {
    var messageID: PubSubID
    var id: PubSubID
    var sender: String
    var type: String
    var value: String
    var timetoken: NSNumber
    var messageTimetoken: NSNumber
}
