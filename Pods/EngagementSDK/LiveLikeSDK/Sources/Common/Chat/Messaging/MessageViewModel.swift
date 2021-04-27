//
//  MessageViewModel.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-22.
//

import UIKit

/// A type representing a unique ID of a `Chat Message`
public struct ChatMessageID: Equatable, Hashable {
    private let internalId: AnyHashable

    /// The stringified id
    public var asString: String {
        return internalId.description
    }

    init(_ hashableID: AnyHashable) {
        self.internalId = hashableID
    }

    public static func == (lhs: ChatMessageID, rhs: ChatMessageID) -> Bool {
        return lhs.internalId == rhs.internalId
    }
}

class MessageViewModel: Equatable {
    var id: ChatMessageID
    var message: NSAttributedString
    let sender: ChatUser?
    let username: String
    let isLocalClient: Bool
    let syncPublishTimecode: String?
    let chatRoomId: String
    private(set) var isDeleted: Bool = false
    let createdAt: Date
    
    var chatReactions: ReactionButtonListViewModel
    var profileImageUrl: URL?
    var bodyImageUrl: URL?
    
    var bodyImageSize: CGSize?
    
    /// Used for debuging video player time
    var videoPlayerDebugTime: Date?
    
    var accessibilityLabel: String?

    let stickerShortcodesInMessage: [String]
    
    init(id: ChatMessageID,
         message: NSAttributedString,
         sender: ChatUser?,
         username: String,
         isLocalClient: Bool,
         syncPublishTimecode: String?,
         chatRoomId: String,
         chatReactions: ReactionButtonListViewModel,
         profileImageUrl: URL?,
         createdAt: Date,
         bodyImageUrl: URL?,
         bodyImageSize: CGSize?,
         accessibilityLabel: String,
         stickerShortcodesInMessage: [String]
    ) {
        self.id = id
        self.message = message
        self.sender = sender
        self.username = username
        self.isLocalClient = isLocalClient
        self.syncPublishTimecode = syncPublishTimecode
        self.chatReactions = chatReactions
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.bodyImageUrl = bodyImageUrl
        self.bodyImageSize = bodyImageSize
        self.stickerShortcodesInMessage = stickerShortcodesInMessage
        self.chatRoomId = chatRoomId
        
        if let videoTimestamp = syncPublishTimecode,
            let videoTimestampInterval = TimeInterval(videoTimestamp) {
            self.videoPlayerDebugTime = Date(timeIntervalSince1970: videoTimestampInterval)
        }
    }

    /// Replaces the message body with 'Redacted'
    func redact(theme: Theme) {
        let attributes = [
            NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14.0),
            NSAttributedString.Key.foregroundColor: theme.messageTextColor
        ]
        let attributedString = NSMutableAttributedString(
            string: "EngagementSDK.chat.messageCell.msgDeleted".localized(),
            attributes: attributes
        )
        self.message = attributedString
        self.accessibilityLabel = ("\(username) \(attributedString.mutableString)")
        self.isDeleted = true
    }
    
    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        // In the case that both ids are 0 for local messages, this is because the user is muted, so the messages should only be considered equal if the send dates are equal
        if lhs.isLocalClient, rhs.isLocalClient, lhs.id == rhs.id {
            return lhs.syncPublishTimecode == rhs.syncPublishTimecode
        }

        return lhs.id == rhs.id
    }
}
