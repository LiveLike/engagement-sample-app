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

public enum ChatSessionError: LocalizedError {
    case concurrentLoadHistoryCalls
    
    public var errorDescription: String? {
        switch self {
        case .concurrentLoadHistoryCalls:
            return "Cannot make concurrent calls to `loadNextHistory`. Wait until `loadNextHistory` completes before calling again."
        }
    }
}

/// A connection to a chat room
public protocol ChatSession: AnyObject {
    var title: String? { get }
    var roomID: String { get }
    
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
    
    /// Are chat avatars displayed next to chat messages
    var isAvatarDisplayed: Bool { get }
    
    /// Set an avatar image to display next to a chat message
    var avatarURL: URL? { get set }
    
    @available(*, deprecated, message: "Please use `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this")
    func pause()

    @available(*, deprecated, message: "Please use `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this")
    func resume()

    func addDelegate(_ delegate: ChatSessionDelegate)
    func removeDelegate(_ delegate: ChatSessionDelegate)
    
    func getMessages(since timestamp: TimeToken, completion: @escaping (Result<[ChatMessage], Error>) -> Void)
    func getMessageCount(since timestamp: TimeToken, completion: @escaping (Result<Int, Error>) -> Void)
    
    /// Sends a user message.
    ///
    /// - Parameters:
    ///   - chatMessage: An object representing the contents of a chat message
    ///   - completion: A callback indicating whether the message was sent or failed where `ChatMessage` represents
    ///   the newly sent message
    /// - Returns: the newly sent message
    @discardableResult
    func sendMessage(_ chatMessage: NewChatMessage, completion: @escaping (Result<ChatMessage, Error>) -> Void) -> ChatMessage
    
    @available(*, deprecated, message: "Please set property `avatarURL` to update user chat room avatar")
    func updateUserChatRoomImage(url: URL, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Loads older chat messages from history.
    /// The loaded messages are inserted into `messages` at index 0.
    /// - Parameter completion: Returns the messages that were loaded.
    func loadNextHistory(completion: @escaping (Result<[ChatMessage], Error>) -> Void)
}

protocol InternalChatSessionProtocol: ChatSession {
    var blockList: BlockList { get }
    var eventRecorder: EventRecorder { get }
    var superPropertyRecorder: SuperPropertyRecorder { get }
    var peoplePropertyRecorder: PeoplePropertyRecorder { get }
    var isReportingEnabled: Bool { get }
    var stickerRepository: StickerRepository { get }
    var recentlyUsedStickers: LimitedArray<Sticker> { get set }
    var reactionsVendor: ReactionVendor { get }
    
    func addInternalDelegate(_ delegate: InternalChatSessionDelegate)
    func removeInternalDelegate(_ delegate: InternalChatSessionDelegate)
    /// Disconnects from messaging client. If this method is invoked,
    /// the current user will be invalidated.
    func disconnect()
    
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

    func loadInitialHistory(completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Exits all channels, however does **not** disconnect from messaging client.
    func unsubscribeFromAllChannels()
}
