//
//  NSMutableAttributedString+Stickers.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-12.
//

import UIKit

extension NSMutableAttributedString {
    func replaceStickerShortcodesInMessage(font: UIFont, stickerRepository: StickerRepository) -> (attributedString: NSMutableAttributedString, stickerLabel: String?) {
        let message = string
        let controlMessage = string
        var shortcode: String?
        var stickerLabels: String?
        do {
            let regex = try NSRegularExpression(pattern: ":(.*?):", options: [])
            let regexRange = NSRange(location: 0, length: message.utf16.count)

            let matches = regex.matches(in: message, options: [], range: regexRange)

            for match in matches.reversed() {
                let nsrange = match.range
                let r = match.range(at: 1)
                if let range = Range(r, in: message) {
                    shortcode = String(message[range])

                    if let shortcode = shortcode, let imageURL = stickerRepository.get(id: shortcode)?.file {
                        
                        // compute sticker label for the accessibility label
                        if stickerLabels == nil {
                            stickerLabels = shortcode
                        } else {
                            stickerLabels?.append(", \(shortcode)")
                        }
                        
                        // retrieve sticker image from the cache
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

        return (self, stickerLabels)
    }
}
