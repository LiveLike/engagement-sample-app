//
//  MessageViewModelFactory.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-22.
//

import Foundation
import UIKit

class MessageViewModelFactory {
    private let stickerPacks: [StickerPack]
    private let reactionsFactory: ReactionVendor
    private let channel: String
    private var theme: Theme = Theme()
    private var mediaRepository: MediaRepository

    init(
        stickerPacks: [StickerPack],
        channel: String,
        reactionsFactory: ReactionVendor,
        mediaRepository: MediaRepository,
        theme: Theme
    ) {
        self.stickerPacks = stickerPacks
        self.channel = channel
        self.reactionsFactory = reactionsFactory
        self.mediaRepository = mediaRepository
        self.theme = theme
    }

    func create(from chatMessage: ChatMessage) -> Promise<MessageViewModel> {
        let sender = chatMessage.sender
        let isLocalClient = sender.isLocalUser

        return firstly {
            Promises.zip(
                reactionsFactory.getReactions(),
                prepareMessage(
                    message: chatMessage.text ?? "",
                    bodyImageURL: chatMessage.imageURL,
                    bodyImageSize: chatMessage.imageSize,
                    username: chatMessage.senderNickname,
                    theme: theme
                )
            )
        }.then { reactionsViewModel, preparedMessage in
            if let profileImageURL = chatMessage.profileImageUrl {
                self.mediaRepository.prefetchMedia(url: profileImageURL)
            }
            
            if let bodyImageURL = chatMessage.imageURL {
                self.mediaRepository.prefetchMedia(url: bodyImageURL)
            }
            
            let messageViewModel = MessageViewModel(
                id: chatMessage.messageID,
                message: preparedMessage.0,
                sender: sender,
                username: sender.nickName,
                isLocalClient: isLocalClient,
                syncPublishTimecode: chatMessage.videoTimestamp?.description,
                chatRoomId: chatMessage.roomID,
                chatReactions: .init(
                    reactionAssets: reactionsViewModel,
                    reactionVotes: chatMessage.reactions
                ),
                profileImageUrl: chatMessage.profileImageUrl,
                createdAt: chatMessage.timestamp,
                bodyImageUrl: chatMessage.imageURL,
                bodyImageSize: chatMessage.imageSize,
                accessibilityLabel: preparedMessage.1,
                stickerShortcodesInMessage: preparedMessage.2
            )
            return Promise(value: messageViewModel)
        }
    }
    
    // swiftlint:disable large_tuple
    private func prepareMessage(
        message: String,
        bodyImageURL: URL?,
        bodyImageSize: CGSize?,
        username: String,
        theme: Theme
    ) -> Promise<(NSAttributedString, String, [String])> {
        return Promise { fulfill, _ in
            self.prepareMessage(
                message: message,
                bodyImageURL: bodyImageURL,
                bodyImageSize: bodyImageSize,
                username: username,
                theme: theme
            ) {
                fulfill(($0, $1, $2))
            }
        }
    }
    
    private func prepareMessage(
        message: String,
        bodyImageURL: URL?,
        bodyImageSize: CGSize?,
        username: String,
        theme: Theme,
        completion: @escaping (NSAttributedString, String, [String]) -> Void
    ) {
        // Prepare image message
        if let bodyImageUrl = bodyImageURL {
            let accessibilityLabel = ("\(username) \("EngagementSDK.chat.accessibility.messageWithImage".localized())")
            if let placeholder = UIImage.coloredImage(
                from: .gray,
                size: bodyImageSize ?? CGSize(width: 50, height: 50)
            ) {
                let stickerAttachment = StickerAttachment(
                    placeholder: placeholder,
                    stickerURL: bodyImageUrl,
                    verticalOffset: 0.0,
                    isLargeImage: true
                )
                let attributedString = NSMutableAttributedString(attachment: stickerAttachment)
                completion(attributedString, accessibilityLabel, [])
            } else {
                completion(NSAttributedString(string: message), accessibilityLabel, [])
            }
        }

        // Prepare text message
        else {
            replaceStickerShortcodeWithImage(
                string: message,
                font: theme.messageTextFont,
                stickerPacks: stickerPacks,
                mediaRepository: mediaRepository
            ) { result in
                switch result {
                case .success(let (attributedString, stickerLabel, stickers)):
                    let accessibilityLabel: String = {
                        var label: String
                        if let stickerLabel = stickerLabel {
                            label = ("\(username) \("EngagementSDK.chat.accessibility.messageWithImage".localized()): [\(stickerLabel)]")
                        } else {
                            label = "\(username) \(message)"
                        }
                        
                        log.dev(label)
                        return label
                    }()
                    completion(attributedString, accessibilityLabel, stickers)
                case .failure(let error):
                    log.error(error)
                    completion(NSAttributedString(string: message), "", [])
                }
            }
        }
    }
    
    private func replaceStickerShortcodeWithImage(
        string: String,
        font: UIFont,
        stickerPacks: [StickerPack],
        mediaRepository: MediaRepository,
        completion: @escaping (Result<(NSMutableAttributedString, String?, [String]), Error>) -> Void
    ) {
        let newString = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.font: font])
        let message = string
        let controlMessage = string
        var shortcode: String?
        var stickerLabels: String?
        var stickerShortcodesFoundInMessage: [String] = []
        do {
            guard let placeholderImage = UIImage.coloredImage(from: .clear, size: CGSize(width: 50, height: 50)) else {
                completion(.success((newString, nil, [])))
                return
            }
             
            // Search for stickers following :sticker: format and get range within string
            let regex = try NSRegularExpression(pattern: ":(.*?):", options: [])
            let regexRange = NSRange(location: 0, length: message.utf16.count)
            let matches = regex.matches(in: message, options: [], range: regexRange)

            // Handle no matches. Complete with original string.
            guard !matches.isEmpty else {
                completion(.success((newString, nil, [])))
                return
            }
            
            // Iterate through all matches and replace shortcode with StickerAttachment
            for match in matches.reversed() {
                let nsrange = match.range
                let r = match.range(at: 1)
                
                // If range cannot be found be safe and just return the original string.
                guard let range = Range(r, in: message) else {
                    completion(.success((newString, nil, [])))
                    return
                }
                shortcode = String(message[range])

                guard
                    let shortcode = shortcode,
                    let sticker = stickerPacks.flatMap({ $0.stickers }).first(where: { $0.shortcode == shortcode})
                else {
                    completion(.success((newString, nil, [])))
                    return
                }

                stickerShortcodesFoundInMessage.append(shortcode)
                
                // compute sticker label for the accessibility label
                if stickerLabels == nil {
                    stickerLabels = shortcode
                } else {
                    stickerLabels?.append(", \(shortcode)")
                }
                
                let fontDescender = font.descender
                let isLargeImage = (controlMessage.replacingOccurrences(of: ":\(shortcode):", with: "").count == 0) && (matches.count == 1)
                let stickerAttachment = StickerAttachment(
                    placeholder: placeholderImage,
                    stickerURL: sticker.file,
                    verticalOffset: fontDescender,
                    isLargeImage: isLargeImage
                )
                let imageAttachmentString = NSAttributedString(attachment: stickerAttachment)
                if newString.rangeExists(nsrange) {
                    newString.replaceCharacters(in: nsrange, with: imageAttachmentString)
                }
            }

            completion(.success((newString, stickerLabels, stickerShortcodesFoundInMessage)))
        } catch {
            log.error("STICKERS Failed to convert sticker shortcodes to images with error: \(String(describing: error))")
            completion(.failure(error))
        }
    }
}
