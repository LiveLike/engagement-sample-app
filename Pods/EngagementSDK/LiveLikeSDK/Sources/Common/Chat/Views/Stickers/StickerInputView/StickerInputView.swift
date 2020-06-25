//
//  StickerInputView.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-10.
//

import UIKit

class StickerInputView: UIView {
    // MARK: IBOutlets

    /// Is used to display a tab of sticker groups
    @IBOutlet var packsCollectionView: UICollectionView! {
        didSet {
            setupPacksCollectionView()
        }
    }
    
    /// Is used to display actual stickers
    @IBOutlet var stickerPacksCollectionView: UICollectionView! {
        didSet {
            setupStickerPacksCollectionView()
        }
    }

    weak var delegate: StickerInputViewDelegate?

    var stickerPacks = [StickerPack]() {
        didSet {
            showStickerPack(at: lastIndexPath)
        }
    }

    // MARK: Private properties

    private var theme: Theme = Theme()
    private var lastIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    init() {
        super.init(frame: .zero)
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {}

    private func setupStickerPacksCollectionView() {
        stickerPacksCollectionView.register(StickerPackCell.self, forCellWithReuseIdentifier: StickerPackCell.reuseIdentifier)
        stickerPacksCollectionView.delegate = self
        stickerPacksCollectionView.dataSource = self
        stickerPacksCollectionView.isAccessibilityElement = false
        
        if let collectionViewLayout = stickerPacksCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewLayout.minimumInteritemSpacing = 0
            collectionViewLayout.minimumLineSpacing = 0
        }
    }

    private func setupPacksCollectionView() {
        packsCollectionView.register(StickerPackPreviewCell.self, forCellWithReuseIdentifier: StickerPackPreviewCell.reuseIdentifier)
        packsCollectionView.delegate = self
        packsCollectionView.dataSource = self
        packsCollectionView.isAccessibilityElement = false
        if let collectionViewLayout = packsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewLayout.minimumInteritemSpacing = 0
            collectionViewLayout.minimumLineSpacing = 0
        }
    }

    override func layoutSubviews() {
        stickerPacksCollectionView.collectionViewLayout.invalidateLayout()
        super.layoutSubviews()
    }

    func setTheme(_ theme: Theme) {
        self.theme = theme
        stickerPacksCollectionView.backgroundColor = theme.chatStickerKeyboardPrimaryColor
        packsCollectionView.backgroundColor = theme.chatStickerKeyboardSecondaryColor
    }

    private func showStickerPack(at indexPath: IndexPath) {
        if stickerPacks.count > 0 {
            lastIndexPath = indexPath
            packsCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            stickerPacksCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        }
    }

    @IBAction func backspacePressed() {
        delegate?.backspacePressed()
    }
}

extension StickerInputView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerPacks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == stickerPacksCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerPackCell.reuseIdentifier, for: indexPath) as? StickerPackCell else { return UICollectionViewCell() }

            let stickerPack = stickerPacks[indexPath.row]
            cell.setTheme(theme)
            cell.stickers = stickerPack.stickers
            cell.delegate = self

            if stickerPack.id == StickerPack.identifier {
                cell.type = .recent
            }

            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerPackPreviewCell.reuseIdentifier, for: indexPath) as? StickerPackPreviewCell else { return UICollectionViewCell() }

            let stickerURL = stickerPacks[indexPath.row].file
            cell.imageView.setImage(url: stickerURL)
            cell.setTheme(theme: theme, stickerName: stickerPacks[indexPath.row].name)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == stickerPacksCollectionView {
            return collectionView.bounds.size
        } else {
            return CGSize(width: 60, height: 40)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == packsCollectionView {
            lastIndexPath = indexPath
            packsCollectionView.reloadData()
            stickerPacksCollectionView.reloadData()
            showStickerPack(at: lastIndexPath)
            stickerPacksCollectionView.layoutIfNeeded()
            stickerPacksCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if stickerPacksCollectionView == scrollView {
            let x = scrollView.contentOffset.x
            let w = scrollView.bounds.size.width
            let currentPage = Int(ceil(x / w))
            lastIndexPath = IndexPath(row: currentPage, section: 0)
            packsCollectionView.selectItem(at: lastIndexPath, animated: false, scrollPosition: .left)
        }
    }

    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let attrs = collectionView.layoutAttributesForItem(at: lastIndexPath)
        let newOriginForOldIndex = attrs?.frame.origin
        return newOriginForOldIndex ?? proposedContentOffset
    }
}

extension StickerInputView {
    class func instanceFromNib() -> StickerInputView {
        // swiftlint:disable force_cast
        return UINib(nibName: "StickerInputView", bundle: Bundle(for: self)).instantiate(withOwner: nil, options: nil).first as! StickerInputView
    }
}

extension StickerInputView: StickerSelectedDelegate {
    func stickerSelected(_ sticker: Sticker) {
        delegate?.stickerSelected(sticker)
    }
}

protocol StickerInputViewDelegate: AnyObject {
    func stickerSelected(_ sticker: Sticker)
    func backspacePressed()
}
