//
//  AnimatedLabel.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-05.
//

import UIKit

class AnimatedLabel: UILabel {
    override var attributedText: NSAttributedString? {
        didSet {
            guard let attributedText = self.attributedText else {
                return
            }

            attributedText.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: attributedText.length), options: .reverse) { value, _, _ in
                if let attachment = value as? StickerAttachment {
                    attachment.containerView = self
                }
            }
        }
    }
}
