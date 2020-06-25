//
//  ChatUser.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-13.
//

import Foundation

/// The `ChatUser` represents a user. The user is identified by the `id`,
/// so the `id` has to be unique.
struct ChatUser {
    /// User ID. This has to be unique.
    let id: ID

    /// Represents the user is activated.
    let isActive: Bool

    /// Whether this user is the local user
    let isLocalUser: Bool

    /// User nickname
    let nickName: String
    
    /// User's badge at the time of this message
    let badgeImageURL: URL?

    let friendDiscoveryKey: String?
    let friendName: String?
    
    init(userId: ID,
         isActive: Bool,
         isLocalUser: Bool,
         nickName: String,
         friendDiscoveryKey: String?,
         friendName: String?,
         badgeImageURL: URL?)
    {
        id = userId
        self.isActive = isActive
        self.isLocalUser = isLocalUser
        self.nickName = nickName
        self.friendDiscoveryKey = friendDiscoveryKey
        self.friendName = friendName
        self.badgeImageURL = badgeImageURL
    }
}

extension ChatUser {
    struct ID {
        private let idString: String

        init(idString: String) {
            self.idString = idString.lowercased()
        }

        var asString: String {
            return idString
        }
    }
}

extension ChatUser.ID: Hashable {}
extension ChatUser.ID: Codable {}
