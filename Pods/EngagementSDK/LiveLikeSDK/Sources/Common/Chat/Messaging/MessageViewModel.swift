//
//  MessageViewModel.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-22.
//

import UIKit

struct ChatMessageID: Equatable, Hashable {
    private let internalId: AnyHashable

    var asString: String {
        return internalId.description
    }

    var asInt64: Int64 {
        guard let intID = Int64(internalId.description) else {
            assertionFailure("Failed trying to convert chat message id \(internalId) to Int64")
            return 0
        }
        return intID
    }

    init(_ hashableID: AnyHashable) {
        self.internalId = hashableID
    }

    static func == (lhs: ChatMessageID, rhs: ChatMessageID) -> Bool {
        return lhs.internalId == rhs.internalId
    }
}

class MessageViewModel: Equatable {
    var id: ChatMessageID
    var message: String
    let sender: ChatUser?
    let username: String
    let isLocalClient: Bool
    let syncPublishTimecode: String?
    let channel: String
    var isDeleted: Bool = false
    var badgeImageURL: URL?
    let createdAt: Date
    
    var chatReactions: ReactionButtonListViewModel

    let stickerRepository: StickerRepository
    var profileImageUrl: URL?
    var bodyImageUrl: URL?

    private let messageReporter: MessageReporter?

    var isReportable: Bool {
        return messageReporter != nil && !isLocalClient
    }
    
    var bodyImageSize: CGSize?
    
    /// Used for debuging video player time
    var videoPlayerDebugTime: Date?
    
    init(id: ChatMessageID,
         message: String,
         sender: ChatUser?,
         username: String,
         isLocalClient: Bool,
         syncPublishTimecode: String?,
         channel: String,
         badgeImageURL: URL?,
         chatReactions: ReactionButtonListViewModel,
         stickerRepository: StickerRepository,
         profileImageUrl: URL?,
         messageReporter: MessageReporter?,
         createdAt: Date,
         bodyImageUrl: URL?,
         bodyImageSize: CGSize?) {
        self.id = id
        self.message = message
        self.sender = sender
        self.username = username
        self.isLocalClient = isLocalClient
        self.syncPublishTimecode = syncPublishTimecode
        self.channel = channel
        self.badgeImageURL = badgeImageURL
        self.chatReactions = chatReactions
        self.stickerRepository = stickerRepository
        self.profileImageUrl = profileImageUrl
        self.messageReporter = messageReporter
        self.createdAt = createdAt
        self.bodyImageUrl = bodyImageUrl
        self.bodyImageSize = bodyImageSize
        
        var imagesToPreDownload = [URL]()
        if let badgeImageURL = badgeImageURL {
            imagesToPreDownload.append(badgeImageURL)
        } else if let imageUrl = profileImageUrl {
            imagesToPreDownload.append(imageUrl)
        } else if let bodyImageUrl = bodyImageUrl {
            imagesToPreDownload.append(bodyImageUrl)
        }
        
        Cache.shared.downloadAndCacheImages(urls: imagesToPreDownload, completion: nil)
        
        if let videoTimestamp = syncPublishTimecode,
            let videoTimestampInterval = TimeInterval(videoTimestamp) {
            self.videoPlayerDebugTime = Date(timeIntervalSince1970: videoTimestampInterval)
        }
    }

    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        // In the case that both ids are 0 for local messages, this is because the user is muted, so the messages should only be considered equal if the send dates are equal
        if lhs.isLocalClient, rhs.isLocalClient, lhs.id == rhs.id {
            return lhs.syncPublishTimecode == rhs.syncPublishTimecode
        }

        return lhs.id == rhs.id
    }
}

extension MessageViewModel {
    func attributedMessage(theme: Theme) -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.font: self.isDeleted ? UIFont.italicSystemFont(ofSize: 14.0) : theme.fontPrimary,
            NSAttributedString.Key.foregroundColor: theme.messageTextColor
        ]

        var attributedString = NSMutableAttributedString(string: isDeleted ? "Redacted" : message, attributes: attributes)
        
        if let bodyImageUrl = bodyImageUrl {
        
            if Cache.shared.has(key: bodyImageUrl.absoluteString) {
                Cache.shared.get(key: bodyImageUrl.absoluteString, completion: { (imageData: Data?) in
                    guard let imageData = imageData else {
                        return log.error("STICKERS Cache found result for key \(bodyImageUrl.absoluteString) but it was nil")
                    }
                    guard let image = UIImage.decode(imageData) else {
                        return log.error("STICKERS Failed to decode to UIImage with result from cache for key \(bodyImageUrl.absoluteString)")
                    }
                    
                    let stickerAttachment = StickerAttachment(image, stickerName: bodyImageUrl.absoluteString, verticalOffset: 0.0, isLargeImage: true)
                    attributedString = NSMutableAttributedString(attachment: stickerAttachment)
                })
            } else {
                if let placeholder = UIImage.coloredImage(from: .gray, size: bodyImageSize ?? CGSize(width: 50, height: 50)) {
                    let stickerAttachment = StickerAttachment(placeholder, stickerName: bodyImageUrl.absoluteString, verticalOffset: 0.0, isLargeImage: true)
                    attributedString = NSMutableAttributedString(attachment: stickerAttachment)
                }
            }
        } else {
            attributedString = attributedString.replaceStickerShortcodesInMessage(font: theme.fontPrimary, stickerRepository: stickerRepository)
        }
        
        return attributedString
    }
}
