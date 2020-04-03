//
//  StickerCell.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-10.
//

import UIKit

class StickerCell: UICollectionViewCell {
    static let reuseIdentifier = "StickerCell"

    var imageView: GIFImageView = {
        let imageView = GIFImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

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
        imageView.constraintsFill(to: contentView)
        backgroundColor = UIColor.clear
        imageView.backgroundColor = UIColor.clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.prepareForReuse()
    }
}
