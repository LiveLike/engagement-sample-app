//
//  ChatMessage.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-14.
//

import Foundation
import UIKit

/// The `UserMessage` struct represents the user **message**.
public class ChatMessage: Equatable {
    
    // MARK: - Public Properties
    
    /// The unique identifer of the message
    public var id: String {
        return messageID.asString
    }
    
    @available(*, deprecated, renamed: "text")
    public var message: String {
        return text ?? ""
    }
    
    /// The unique id of the message's sender
    public let senderID: String
    
    /// The nickname of the message's sender
    public let senderNickname: String
    
    @available(*, deprecated, renamed: "senderNickname")
    public var nickname: String {
        return sender.nickName
    }
    
    /// The message after it has been filtered.
    public var filteredMessage: String?
    
    /// The reason(s) why a message was filtered.
    public var filteredReasons: Set<ChatFilter>
    
    /// Has the message been filtered.
    public var isMessageFiltered: Bool {
        return filteredReasons.count > 0
    }
    
    /// The text component of the message
    public let text: String?
    
    /// The URL of the message's image component
    public let imageURL: URL?
    
    /// The CGSize of the message's image component
    public let imageSize: CGSize?
    
    /// The timestamp of when this message was created
    public let timestamp: Date

    /// The TimeToken of when this message was created.
    /// Used for `getMessages` and `getMessageCount` methods of `ContentSession`
    public let createdAt: TimeToken
    
    /// True if the current user is the message's sender
    public let isMine: Bool
    
    // MARK: - Internal Properties
    
    /// Unique message ID.
    var messageID: ChatMessageID
    
    /// Chat Room ID
    let roomID: String
    
    /// Sender of the **message**. This is represented by `ChatUser` struct.
    let sender: ChatUser

    /// The UNIX Epoch for the senders playhead position.
    let videoTimestamp: EpochTime?

    var reactions: ReactionVotes
    
    // chat cell image (avatar)
    let profileImageUrl: URL?

    init(
        id: ChatMessageID,
        roomID: String,
        message: String,
        sender: ChatUser,
        videoTimestamp: EpochTime?,
        reactions: ReactionVotes,
        timestamp: Date,
        profileImageUrl: URL?,
        createdAt: TimeToken,
        bodyImageUrl: URL?,
        bodyImageSize: CGSize?,
        filteredMessage: String?,
        filteredReasons: Set<ChatFilter>
    ) {
        self.messageID = id
        self.roomID = roomID
        self.text = message
        self.sender = sender
        self.videoTimestamp = videoTimestamp
        self.reactions = reactions
        self.profileImageUrl = profileImageUrl
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.imageURL = bodyImageUrl
        self.imageSize = bodyImageSize
        self.filteredMessage = filteredMessage
        self.filteredReasons = filteredReasons
        self.senderID = sender.id.asString
        self.senderNickname = sender.nickName
        self.isMine = sender.isLocalUser
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.messageID == rhs.messageID
    }
}

// MARK: - Convenience Init
extension ChatMessage {
    convenience init(
        from chatPubnubMessage: PubSubChatPayload,
        chatRoomID: String,
        channel: String,
        timetoken: TimeToken,
        actions: [PubSubMessageAction],
        userID: ChatUser.ID
    ) {
        let senderID = ChatUser.ID(idString: chatPubnubMessage.senderId ?? "deleted_\(chatPubnubMessage.id)")
        let chatUser = ChatUser(
            userId: senderID,
            isActive: false,
            isLocalUser: senderID == userID,
            nickName: chatPubnubMessage.senderNickname ?? "deleted_\(chatPubnubMessage.id)",
            friendDiscoveryKey: nil,
            friendName: nil
        )

        let reactions: ReactionVotes = {
            var allVotes: [ReactionVote] = []
            actions.forEach { action in
                guard action.type == MessageActionType.reactionCreated.rawValue else { return }
                let voteID = ReactionVote.ID(action.id)
                let reactionID = ReactionID(fromString: action.value)
                let reaction = ReactionVote(
                    voteID: voteID,
                    reactionID: reactionID,
                    isMine: action.sender == userID.asString
                )
                allVotes.append(reaction)
            }
            return ReactionVotes(allVotes: allVotes)
        }()

        self.init(
            id: ChatMessageID(chatPubnubMessage.id),
            roomID: chatRoomID,
            message: chatPubnubMessage.message ?? "deleted_\(chatPubnubMessage.id)",
            sender: chatUser,
            videoTimestamp: chatPubnubMessage.programDateTime?.timeIntervalSince1970,
            reactions: reactions,
            timestamp: timetoken.approximateDate,
            profileImageUrl: chatPubnubMessage.senderImageUrl,
            createdAt: timetoken,
            bodyImageUrl: nil,
            bodyImageSize: nil,
            filteredMessage: chatPubnubMessage.filteredMessage,
            filteredReasons: chatPubnubMessage.filteredSet
        )
    }

    convenience init(
        from chatPubnubMessage: PubSubImagePayload,
        chatRoomID: String,
        channel: String,
        timetoken: TimeToken,
        actions: [PubSubMessageAction],
        userID: ChatUser.ID
    ) {
        let senderID = ChatUser.ID(idString: chatPubnubMessage.senderId)
        let chatUser = ChatUser(
            userId: senderID,
            isActive: false,
            isLocalUser: senderID == userID,
            nickName: chatPubnubMessage.senderNickname,
            friendDiscoveryKey: nil,
            friendName: nil
        )

        let reactions: ReactionVotes = {
            var allVotes: [ReactionVote] = []
            actions.forEach { action in
                guard action.type == MessageActionType.reactionCreated.rawValue else { return }
                let voteID = ReactionVote.ID(action.id)
                let reactionID = ReactionID(fromString: action.value)
                let reaction = ReactionVote(
                    voteID: voteID,
                    reactionID: reactionID,
                    isMine: action.sender == userID.asString
                )
                allVotes.append(reaction)
            }
            return ReactionVotes(allVotes: allVotes)
        }()

        self.init(
            id: ChatMessageID(chatPubnubMessage.id),
            roomID: chatRoomID,
            message: "", // no message
            sender: chatUser,
            videoTimestamp: chatPubnubMessage.programDateTime?.timeIntervalSince1970,
            reactions: reactions,
            timestamp: timetoken.approximateDate,
            profileImageUrl: chatPubnubMessage.senderImageUrl,
            createdAt: timetoken,
            bodyImageUrl: chatPubnubMessage.imageUrl,
            bodyImageSize: CGSize(width: chatPubnubMessage.imageWidth, height: chatPubnubMessage.imageHeight),
            filteredMessage: nil,
            filteredReasons: Set()
        )
    }

}

/// The filter type that has been applied to the chat message
public enum ChatFilter: String, Codable {
    /// Catch-all type for any kind of filtering
    case filtered
    
    /// Chat message has been filtered for profanity
    case profanity
}
