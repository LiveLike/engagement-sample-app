//
//  StickerAttachment.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-07.
//

import UIKit

class StickerAttachment: NSTextAttachment {
    // MARK: Internal properties

    weak var containerView: UIView?

    // MARK: Private properties

    private let largeImageHeight = CGFloat(100)
    private var verticalOffset: CGFloat = 0.0
    private var isLargeImage = false
    private lazy var imageView: GIFImageView = {
        GIFImageView(frame: .zero)
    }()

    private var stickerURL: URL!

    // To vertically center the image, pass in the font descender as the vertical offset.
    // We cannot get this info from the text container since it is sometimes nil when `attachmentBoundsForTextContainer`
    // is called.
    convenience init(placeholder: UIImage, stickerURL: URL, verticalOffset: CGFloat = 0.0, isLargeImage: Bool) {
        self.init()
        self.image = placeholder
        self.stickerURL = stickerURL
        self.verticalOffset = verticalOffset
        self.isLargeImage = isLargeImage
    }

    override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> UIImage? {
        imageView.frame = CGRect(x: imageBounds.origin.x, y: imageBounds.origin.y - imageBounds.size.height, width: imageBounds.size.width, height: imageBounds.size.height)
        containerView?.addSubview(imageView)
        imageView.setImage(url: stickerURL)
        imageView.startAnimating()
        return nil
    }

    override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        // Makes the sticker the same height as the text unless it is a large image
        let bloatStickerHeight = lineFrag.size.height * 0.33
        let height = isLargeImage ? largeImageHeight : lineFrag.size.height + bloatStickerHeight
        var scale: CGFloat = 1.0
        let imageSize = image!.size

        if height < imageSize.height {
            scale = height / imageSize.height
        }

        return CGRect(x: 0, y: verticalOffset - (bloatStickerHeight / 2), width: imageSize.width * scale, height: imageSize.height * scale)
    }

    func prepareForReuse() {
        imageView.prepareForReuse()
        imageView.removeFromSuperview()
    }

    deinit {
        imageView.removeFromSuperview()
    }
}
