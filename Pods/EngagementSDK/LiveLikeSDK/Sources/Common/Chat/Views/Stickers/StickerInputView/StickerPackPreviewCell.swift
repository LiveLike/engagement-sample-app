//
//  StickerPackPreviewCell.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-13.
//

import UIKit

/// This cell is used to display sticker group previews in the keyboard
/// A user clicks on this cell to display more stickers from the sticker group
class StickerPackPreviewCell: UICollectionViewCell {
    static let reuseIdentifier = "StickerPackPreviewCell"

    var imageView: GIFImageView = {
        let imageView = GIFImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override var isSelected: Bool {
        didSet {
            updateTheme()
        }
    }

    private var theme = Theme()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCell()
    }

    private func setupCell() {
        contentView.addSubview(imageView)
        updateTheme()

        let constraints = [
            contentView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            contentView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -8),
            contentView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -16)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setTheme(theme: Theme, stickerName: String) {
        self.theme = theme
        updateTheme()
        setUpAccessibility(stickerName: stickerName)
    }

    private func updateTheme() {
        backgroundColor = isSelected ? theme.chatStickerKeyboardPrimaryColor : UIColor.clear
        imageView.alpha = isSelected ? 1.0 : 0.4
        imageView.backgroundColor = UIColor.clear
    }
    
    private func setUpAccessibility(stickerName: String) {
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "\(stickerName) Sticker Tab"
        imageView.accessibilityTraits = .button
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.prepareForReuse()
    }
}
