//
//  PubSubChannelMessage.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

struct PubSubChannelMessage {
    var pubsubID: PubSubID
    var message: [String: Any]
    var createdAt: NSNumber
    var messageActions: [PubSubMessageAction]

    mutating func addAction(_ messageAction: PubSubMessageAction) {
        messageActions.append(messageAction)
    }
}
