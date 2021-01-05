//
//  ChatSessionConfig.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 3/6/20.
//

import Foundation

/// Configuration to connect to a chat room
public struct ChatSessionConfig {
    /// The unique id of the Chat Room to connect
    public let roomID: String
    
    /// A timesource used for Spoiler Free Sync
    public var syncTimeSource: PlayerTimeSource?
    
    /// The maximum number of messages per history request.
    ///
    /// A lower number may result in faster load times.
    /// Maximum is 100.
    /// Default is 50.
    public var messageHistoryLimit: UInt = 50
    
    /// Show or hide user avatar next to a chat message
    public var shouldDisplayAvatar: Bool = false
    
    /// Initialize a ChatSessionConfig
    /// - Parameter roomID: The unique id of the Chat Room to connect
    public init(roomID: String) {
        self.roomID = roomID
    }
}
