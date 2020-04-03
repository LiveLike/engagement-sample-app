//
//  MessageViewModelFactory.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-22.
//

import Foundation
import UIKit

class MessageViewModelFactory {
    private let stickerRepository: StickerRepository
    private let reactionsFactory: ReactionsViewModelFactory
    private let messageReporter: MessageReporter?
    private let channel: String
    private var theme: Theme = Theme()

    init(
        stickerRepository: StickerRepository,
        channel: String,
        reactionsFactory: ReactionsViewModelFactory,
        messageReporter: MessageReporter?
    ) {
        self.stickerRepository = stickerRepository
        self.channel = channel
        self.reactionsFactory = reactionsFactory
        self.messageReporter = messageReporter
    }

    func create(from chatMessage: ChatMessageType) -> Promise<MessageViewModel> {
        let sender = chatMessage.sender
        let isLocalClient = sender.isLocalUser

        return firstly {
            reactionsFactory.make(from: chatMessage.reactions)
        }.then { reactionsViewModel in
            let messageViewModel = MessageViewModel(
                id: chatMessage.id,
                message: chatMessage.message,
                sender: sender,
                username: sender.nickName,
                isLocalClient: isLocalClient,
                syncPublishTimecode: chatMessage.videoTimestamp?.description,
                channel: chatMessage.roomID,
                badgeImageURL: sender.badgeImageURL,
                chatReactions: reactionsViewModel,
                stickerRepository: self.stickerRepository,
                profileImageUrl: chatMessage.profileImageUrl,
                messageReporter: self.messageReporter,
                createdAt: chatMessage.timestamp,
                bodyImageUrl: chatMessage.bodyImageUrl,
                bodyImageSize: chatMessage.bodyImageSize)
            return Promise(value: messageViewModel)
        }
    }

    private func createChatMessage(messageString: String) -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.font: theme.fontPrimary,
            NSAttributedString.Key.foregroundColor: theme.messageTextColor
        ]

        var attributedString = NSMutableAttributedString(string: messageString, attributes: attributes)
        attributedString = attributedString.replaceStickerShortcodesInMessage(font: theme.fontPrimary, stickerRepository: stickerRepository)

        return attributedString
    }
}
