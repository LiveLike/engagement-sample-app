//
//  ChatMessagingClient.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-29.
//

import Foundation

protocol MessageReporter {
    func report(messageViewModel: MessageViewModel) -> Promise<Void>
}

typealias ReactionIDs = Set<ReactionID>

protocol ChatRoom {

    var roomID: String { get }

    /// Disconnects from messaging client. If this method is invoked,
    /// the current user will be invalidated.
    func disconnect()

    /// Disconnects from client but does not remove list of connected channels.
    func pause()

    /// Reconnects user and joins all previous channels.
    func resume()

    /// Enters the channel
    ///
    /// - Parameter channel: The channel URL.
    func enterOpenChannel(_ channel: String) -> Promise<Void>

    /// Enters the channel for a specific session
    ///
    /// - Parameters:
    ///   - channel: The channel URL.
    ///   - sessionId: unique session id
    /// - Returns: A `Promise` with userId
    func enterOpenChannel(_ channel: String, sessionId: String) -> Promise<Void>

    /// Exits the channel
    ///
    /// - Parameter channel: The channel URL.
    func exitChannel(_ channel: String) -> Promise<Void>

    /// Exits the channel for a specific session
    ///
    /// - Parameters:
    ///   - channel: The channel URL.
    ///   - sessionId: unique session id
    func exitChannel(_ channel: String, sessionId: String)

    /// Sends a user message.
    ///
    /// - Parameters:
    ///   - clientMessage: The message text.
    ///   - completion: callback indicating the message was sent
    func sendMessage(_ clientMessage: ClientMessage) -> Promise<ChatMessageID>

    /// Updates an already posted message
    @discardableResult
    func updateMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID>
    
    /// Deletes an already posted message
    @discardableResult
    func deleteMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID>
    
    func sendMessageReaction(
        _ messageID: ChatMessageID,
        reaction: ReactionID,
        reactionsToRemove: ReactionVote.ID?
    ) -> Promise<Void>

    func removeMessageReactions(
        reaction: ReactionVote.ID,
        fromMessageWithID messageID: ChatMessageID
    ) -> Promise<Void>

    /// Load recent history for chat channel.
    ///
    /// - Parameters:
    ///   - limit: limit of messages to load. Defualt is 50 up to a maximum of 200.
    ///   - channel: The channel URL.
    func loadNewestMessagesFromHistory(limit: Int) -> Promise<Void>
    
    /// Loads previous messages from history.
    /// Subsequent calls to this will continue to load from the oldest message loaded.
    func loadPreviousMessagesFromHistory(limit: Int) -> Promise<Void>

    func loadInitialHistory(limit: Int) -> Promise<Void>
    
    /// Exits all channels, however does **not** disconnect from messaging client.
    func unsubscribeFromAllChannels()

    var availableReactions: [ReactionID] { get set }
    
    /// Updates the image represinting the user in Chat
    /// - Parameter url: a string url of the image
    func updateUserChatImage(url: URL) -> Promise<Void>
}
