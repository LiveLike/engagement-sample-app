//
//  ChatRoomResource.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/25/19.
//

import Foundation

struct ChatRoomResource: Decodable {
    var id: String
    var channels: Channels
    var uploadUrl: URL

    struct Channels: Decodable {
        var chat: Channel
        var reactions: Channel?
        var control: Channel?
    }

    struct Channel: Decodable {
        var pubnub: String?
    }
}
