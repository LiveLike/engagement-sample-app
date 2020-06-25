//
//  ChatRoomMembershipModels.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 6/17/20.
//

import UIKit

// Represents a result page when retrieving all user memberships of a room
struct ChatRoomMembershipPage: Decodable {
    var results: [ChatRoomMember]
    var next: URL?
    var previous: URL?
}

// Represents a result page when retrieving all chat rooms a user is a member of
struct UserChatRoomMembershipPage: Decodable {
    var results: [ChatRoomMembership]
    var next: URL?
    var previous: URL?
}

/// Represents a user member that belonds to a chat room
public struct ChatRoomMember: Decodable {
    public let id: String
    public let url: URL
    public let profile: ProfileResource
}

// Represents a chat room when querying the backend for user's chat room memeberships
struct ChatRoomMembership: Decodable {
    public let id: String
    public let url: URL
    public let chatRoom: ChatRoomResource
}
