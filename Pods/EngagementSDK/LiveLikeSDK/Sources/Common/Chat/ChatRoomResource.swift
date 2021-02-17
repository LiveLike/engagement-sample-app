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
    var title: String?
    var reportMessageUrl: URL
    var stickerPacksUrl: URL
    var reactionPacksUrl: URL
    var membershipsUrl: URL
    var mutedStatusUrlTemplate: String
    var visibility: ChatRoomVisibilty

    struct Channels: Decodable {
        var chat: Channel
        var reactions: Channel?
        var control: Channel?
    }

    struct Channel: Decodable {
        var pubnub: String?
    }
}

struct ChatUserMuteStatusResource: Decodable {
    let isMuted: Bool
}

/// Used to signify current chat user's mute status
public struct ChatUserMuteStatus {
    public let isMuted: Bool
}

/// Used to signify the visibility of a chat room
public enum ChatRoomVisibilty: String, Codable, CaseIterable {
    case members
    case everyone
}

/// Used as a return object when calling `getChatRoomInfo()`
public struct ChatRoomInfo {
    public let id: String
    public let title: String?
    public let visibility: ChatRoomVisibilty
}
