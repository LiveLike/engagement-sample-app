//
//  StickerPackCell.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-11.
//

import UIKit

class StickerPackCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "StickerPackCell"

    var type: StickerPackType = .normal
    var stickers = [Sticker]() {
        didSet {
            collectionView.reloadData()
        }
    }

    weak var delegate: StickerSelectedDelegate?

    var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumInteritemSpacing = 4
        collectionViewLayout.minimumLineSpacing = 16
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: StickerCell.reuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView.isAccessibilityElement = false
        collectionView.accessibilityLabel = "Sticker Collection"
        collectionView.accessibilityTraits = .allowsDirectInteraction
        return collectionView
    }()

    lazy var noRecentsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = UIColor(white: 1.0, alpha: 0.4)
        label.text = NSLocalizedString("You haven’t posted any stickers yet.\nGo post it!", comment: "No recent stickers are available yet.")
        return label
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
        collectionView.delegate = self
        collectionView.dataSource = self
        contentView.addSubview(collectionView)
        let constraints = [
            contentView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            contentView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setTheme(_ theme: Theme) {
        if type == .recent {
            noRecentsLabel.font = theme.fontPrimary
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if type == .recent {
            if stickers.count == 0 {
                contentView.addSubview(noRecentsLabel)
                let constraints = [
                    contentView.centerXAnchor.constraint(equalTo: noRecentsLabel.centerXAnchor),
                    contentView.centerYAnchor.constraint(equalTo: noRecentsLabel.centerYAnchor)
                ]
                NSLayoutConstraint.activate(constraints)
            } else {
                noRecentsLabel.removeFromSuperview()
            }
        }

        return stickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.reuseIdentifier, for: indexPath) as? StickerCell else { return UICollectionViewCell() }

        let stickerKey = stickers[indexPath.row].file.absoluteString
        let accessibilityLabel = "\(stickers[indexPath.row].shortcode) Sticker"
        cell.imageView.setImage(key: stickerKey)
        cell.isAccessibilityElement = false
        cell.imageView.isAccessibilityElement = true
        cell.imageView.accessibilityLabel = accessibilityLabel
        cell.imageView.accessibilityTraits = .button

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 48, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.stickerSelected(stickers[indexPath.row])
    }
}

protocol StickerSelectedDelegate: AnyObject {
    func stickerSelected(_ sticker: Sticker)
}
