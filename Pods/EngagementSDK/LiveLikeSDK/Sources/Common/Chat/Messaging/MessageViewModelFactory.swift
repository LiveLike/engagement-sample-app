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
    private let reactionsFactory: ReactionsViewModelFactory
    private let channel: String
    private var theme: Theme = Theme()
    private var mediaRepository: MediaRepository

    init(
        stickerPacks: [StickerPack],
        channel: String,
        reactionsFactory: ReactionsViewModelFactory,
        mediaRepository: MediaRepository
    ) {
        self.stickerPacks = stickerPacks
        self.channel = channel
        self.reactionsFactory = reactionsFactory
        self.mediaRepository = mediaRepository
    }

    func create(from chatMessage: ChatMessage) -> Promise<MessageViewModel> {
        let sender = chatMessage.sender
        let isLocalClient = sender.isLocalUser

        return firstly {
            Promises.zip(
                reactionsFactory.make(from: chatMessage.reactions),
                prepareMessage(
                    message: chatMessage.message,
                    bodyImageURL: chatMessage.bodyImageUrl,
                    bodyImageSize: chatMessage.bodyImageSize,
                    username: chatMessage.nickname,
                    theme: theme
                )
            )
        }.then { reactionsViewModel, preparedMessage in
            
            if let badgeImageURL = sender.badgeImageURL {
                self.mediaRepository.prefetchMedia(url: badgeImageURL)
            }
            
            if let profileImageURL = chatMessage.profileImageUrl {
                self.mediaRepository.prefetchMedia(url: profileImageURL)
            }
            
            if let bodyImageURL = chatMessage.bodyImageUrl {
                self.mediaRepository.prefetchMedia(url: bodyImageURL)
            }
            
            let messageViewModel = MessageViewModel(
                id: chatMessage.id,
                message: preparedMessage.0,
                sender: sender,
                username: sender.nickName,
                isLocalClient: isLocalClient,
                syncPublishTimecode: chatMessage.videoTimestamp?.description,
                channel: chatMessage.roomID,
                badgeImageURL: sender.badgeImageURL,
                chatReactions: reactionsViewModel,
                profileImageUrl: chatMessage.profileImageUrl,
                createdAt: chatMessage.timestamp,
                bodyImageUrl: chatMessage.bodyImageUrl,
                bodyImageSize: chatMessage.bodyImageSize,
                accessibilityLabel: preparedMessage.1)
            return Promise(value: messageViewModel)
        }
    }
    
    private func prepareMessage(
        message: String,
        bodyImageURL: URL?,
        bodyImageSize: CGSize?,
        username: String,
        theme: Theme
    ) -> Promise<(NSAttributedString, String)> {
        return Promise { fulfill, _ in
            self.prepareMessage(
                message: message,
                bodyImageURL: bodyImageURL,
                bodyImageSize: bodyImageSize,
                username: username,
                theme: theme
            ) {
                fulfill(($0, $1))
            }
        }
    }
    
    private func prepareMessage(
        message: String,
        bodyImageURL: URL?,
        bodyImageSize: CGSize?,
        username: String,
        theme: Theme,
        completion: @escaping (NSAttributedString, String) -> Void
    ) {
        // Prepare image message
        if let bodyImageUrl = bodyImageURL {
            let accessibilityLabel = ("\(username) Image")
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
                completion(attributedString, accessibilityLabel)
            } else {
                completion(NSAttributedString(string: message), accessibilityLabel)
            }
        }

        // Prepare text message
        else {
            replaceStickerShortcodeWithImage(
                string: message,
                font: theme.fontPrimary,
                stickerPacks: stickerPacks,
                mediaRepository: mediaRepository
            ) { result in
                switch result {
                case .success(let (attributedString, stickerLabel)):
                    let accessibilityLabel: String = {
                        var label: String
                        if let stickerLabel = stickerLabel {
                            label = ("\(username) Image: [\(stickerLabel)]")
                        } else {
                            label = "\(username) \(message)"
                        }
                        return label
                    }()
                    completion(attributedString, accessibilityLabel)
                case .failure(let error):
                    log.error(error)
                    completion(NSAttributedString(string: message), "")
                }
            }
        }
    }
    
    private func replaceStickerShortcodeWithImage(
        string: String,
        font: UIFont,
        stickerPacks: [StickerPack],
        mediaRepository: MediaRepository,
        completion: @escaping (Result<(NSMutableAttributedString, String?), Error>) -> Void
    ) {
        let newString = NSMutableAttributedString(string: string)
        let message = string
        let controlMessage = string
        var shortcode: String?
        var stickerLabels: String?
        do {
            guard let placeholderImage = UIImage.coloredImage(from: .clear, size: CGSize(width: 50, height: 50)) else {
                completion(.success((newString, nil)))
                return
            }
             
            // Search for stickers following :sticker: format and get range within string
            let regex = try NSRegularExpression(pattern: ":(.*?):", options: [])
            let regexRange = NSRange(location: 0, length: message.utf16.count)
            let matches = regex.matches(in: message, options: [], range: regexRange)

            // Handle no matches. Complete with original string.
            guard !matches.isEmpty else {
                completion(.success((newString, nil)))
                return
            }
            
            // Iterate through all matches and replace shortcode with StickerAttachment
            for match in matches.reversed() {
                let nsrange = match.range
                let r = match.range(at: 1)
                
                // If range cannot be found be safe and just return the original string.
                guard let range = Range(r, in: message) else {
                    completion(.success((newString, nil)))
                    return
                }
                shortcode = String(message[range])

                guard
                    let shortcode = shortcode,
                    let sticker = stickerPacks.flatMap({ $0.stickers }).first(where: { $0.shortcode == shortcode})
                else {
                    completion(.success((newString, nil)))
                    return
                }
                
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
                completion(.success((newString, stickerLabels)))
            }
        } catch {
            log.error("STICKERS Failed to convert sticker shortcodes to images with error: \(String(describing: error))")
            completion(.failure(error))
        }
    }
}
