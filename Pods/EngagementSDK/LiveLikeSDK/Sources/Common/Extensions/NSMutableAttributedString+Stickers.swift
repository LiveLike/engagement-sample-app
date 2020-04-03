//
//  NSMutableAttributedString+Stickers.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-12.
//

import UIKit

extension NSMutableAttributedString {
    func replaceStickerShortcodesInMessage(font: UIFont, stickerRepository: StickerRepository) -> NSMutableAttributedString {
        let message = string
        let controlMessage = string

        do {
            let regex = try NSRegularExpression(pattern: ":(.*?):", options: [])
            let regexRange = NSRange(location: 0, length: message.utf16.count)

            let matches = regex.matches(in: message, options: [], range: regexRange)

            for match in matches.reversed() {
                let nsrange = match.range
                let r = match.range(at: 1)
                if let range = Range(r, in: message) {
                    let shortcode = String(message[range])

                    if let imageURL = stickerRepository.get(id: shortcode)?.file {
                        Cache.shared.get(key: imageURL.absoluteString, completion: { (imageData: Data?) in
                            guard let imageData = imageData else {
                                return log.error("STICKERS Cache found result for key \(imageURL.absoluteString) but it was nil")
                            }
                            guard let image = UIImage.decode(imageData) else {
                                return log.error("STICKERS Failed to decode to UIImage with result from cache for key \(imageURL.absoluteString)")
                            }

                            let fontDescender = font.descender
                            let isLargeImage = (controlMessage.replacingOccurrences(of: ":\(shortcode):", with: "").count == 0) && (matches.count == 1)
                            let stickerAttachment = StickerAttachment(image, stickerName: imageURL.absoluteString, verticalOffset: fontDescender, isLargeImage: isLargeImage)
                            let imageAttachmentString = NSAttributedString(attachment: stickerAttachment)
                            self.replaceCharacters(in: nsrange, with: imageAttachmentString)
                        })
                    }
                }
            }
        } catch {
            log.error("STICKERS Failed to convert sticker shortcodes to images.")
            log.error(error.localizedDescription)
            print(error)
        }

        return self
    }
}
