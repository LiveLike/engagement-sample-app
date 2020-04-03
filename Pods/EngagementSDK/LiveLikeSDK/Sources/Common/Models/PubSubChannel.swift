//
//  PubSubChannel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/27/19.
//

import Foundation

/// Represents a delegate to a PubSubChannel
protocol PubSubChannelDelegate: AnyObject {
    func channel(_ channel: PubSubChannel, messageCreated message: PubSubChannelMessage)
    func channel(_ channel: PubSubChannel, messageActionCreated messageAction: PubSubMessageAction)
    func channel(
        _ channel: PubSubChannel,
        messageActionDeleted messageActionID: PubSubID,
        messageID: PubSubID
    )
}

/// Represents a single channel of a publish/subscribe networking service
protocol PubSubChannel {
    var delegate: PubSubChannelDelegate? { get set }
    var name: String { get }
    func send(
        _ message: String,
        completion: @escaping (Result<PubSubID, Error>) -> Void
    )
    func sendMessageAction(
        type: String,
        value: String,
        messageID: PubSubID,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
    func removeMessageAction(
        messageID: PubSubID,
        messageActionID: PubSubID,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
    func fetchHistory(
        oldestMessageDate: Date?,
        newestMessageDate: Date?,
        limit: UInt,
        completion: @escaping (Result<PubSubHistoryResult, Error>) -> Void
    )
    var pauseStatus: PauseStatus { get }
    /// Temporarily pauses the channel
    func pause()
    /// Resumes a paused channel
    func resume()
    /// Stops the channel from receiving updates
    func disconnect()
}
