//
//  ChatSession.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 3/6/20.
//

import Foundation

public protocol ChatSessionDelegate: AnyObject {
    func chatSession(_ chatSession: ChatSession, didRecieveNewMessage message: ChatMessage)
}

protocol InternalChatSessionDelegate: ChatSessionDelegate {
    func chatSession(_ chatSession: ChatSession, didRecieveMessageHistory messages: [ChatMessage])
    func chatSession(_ chatSession: ChatSession, didRecieveMessageUpdate message: ChatMessage)
    func chatSession(_ chatSession: ChatSession, didRecieveMessageDeleted messageID: ChatMessageID)
    func chatSession(_ chatSession: ChatSession, didRecieveError error: Error)
}

/// A connection to a chat room
public protocol ChatSession: AnyObject {
    var title: String? { get }
    var roomID: String { get }
    /// Disconnects from client but does not remove list of connected channels.
    func pause()

    /// Reconnects user and joins all previous channels.
    func resume()

    func addDelegate(_ delegate: ChatSessionDelegate)
    func removeDelegate(_ delegate: ChatSessionDelegate)
    
    /// The array of all chat room messages that have been loaded
    ///
    /// The messages are in descending order of TimeToken.
    ///
    /// `messages.first` is the oldest message (if it exists)
    ///
    /// `messages.last` is the most recent message. (if it exists)
    ///
    /// When more messages are loaded from history, they are inserted into the array at index 0. Array access by index is not advised.
    var messages: [ChatMessage] { get }
    
    func getMessages(since timestamp: TimeToken, completion: @escaping (Result<[ChatMessage], Error>) -> Void)
    func getMessageCount(since timestamp: TimeToken, completion: @escaping (Result<Int, Error>) -> Void)
}

protocol InternalChatSessionProtocol: ChatSession {
    var blockList: BlockList { get }
    var eventRecorder: EventRecorder { get }
    var reactionsViewModelFactory: ReactionsViewModelFactory { get }
    var isReportingEnabled: Bool { get }
    var stickerRepository: StickerRepository { get }
    var recentlyUsedStickers: LimitedArray<Sticker> { get set }

    var reactionsVendor: ReactionVendor { get }
    
    func addInternalDelegate(_ delegate: InternalChatSessionDelegate)
    func removeInternalDelegate(_ delegate: InternalChatSessionDelegate)
    /// Disconnects from messaging client. If this method is invoked,
    /// the current user will be invalidated.
    func disconnect()

    /// Sends a user message.
    ///
    /// - Parameters:
    ///   - clientMessage: The message text.
    ///   - completion: callback indicating the message was sent
    func sendMessage(_ clientMessage: ClientMessage) -> Promise<ChatMessageID>
    
    /// Deletes an already posted message
    @discardableResult
    func deleteMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID>
    
    func reportMessage(withID id: ChatMessageID, completion: @escaping (Result<Void, Error>) -> Void)
    
    func sendMessageReaction(
        _ messageID: ChatMessageID,
        reaction: ReactionID,
        reactionsToRemove: ReactionVote.ID?
    ) -> Promise<Void>

    func removeMessageReactions(
        reaction: ReactionVote.ID,
        fromMessageWithID messageID: ChatMessageID
    ) -> Promise<Void>

    /// Loads previous messages from history.
    /// Subsequent calls to this will continue to load from the oldest message loaded.
    func loadPreviousMessagesFromHistory() -> Promise<Void>

    func loadInitialHistory(completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Exits all channels, however does **not** disconnect from messaging client.
    func unsubscribeFromAllChannels()

    var availableReactions: [ReactionID] { get set }
    
    /// Updates the image represinting the user in Chat
    /// - Parameter url: a string url of the image
    func updateUserChatImage(url: URL) -> Promise<Void>
}
