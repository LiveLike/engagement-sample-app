//
//  ChatMessage.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-18.
//

import Foundation

/// Represents a message of a user
@objc public class ChatMessage: NSObject {

    /// The display name of the user
    public let displayName: String

    /// The contents of the chat message
    public let message: String?

    /// The timestamp that the message was created
    public let timestamp: Date

    internal required init(senderUsername: String, message: String?, timestamp: Date) {
        self.displayName = senderUsername
        self.message = message
        self.timestamp = timestamp
    }
}
