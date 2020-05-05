//
//  PubSubHistoryResult.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

struct PubSubHistoryResult {
    var newestMessageTimetoken: TimeToken
    var oldestMessageTimetoken: TimeToken
    var messages: [PubSubChannelMessage]
}
