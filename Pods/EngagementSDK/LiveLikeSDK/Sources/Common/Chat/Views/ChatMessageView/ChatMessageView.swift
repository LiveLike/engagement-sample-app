//
//  ChatMessageCell.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-19.
//

import UIKit

class ChatMessageView: UIView {
    // MARK: - Outlets

    @IBOutlet weak private var messageLabel: AnimatedLabel!
    
    @IBOutlet weak private var topBorder: UIView!
    @IBOutlet weak private var topBorderHeight: NSLayoutConstraint!
    @IBOutlet weak private var bottomBorder: UIView!
    @IBOutlet weak private var bottomBorderHeight: NSLayoutConstraint!
    
    @IBOutlet weak private var messageViewHolderLeading: NSLayoutConstraint!
    @IBOutlet weak private var usernameLabel: UILabel!
    @IBOutlet weak private var messageViewHolder: UIView!
    @IBOutlet weak private var messageBackground: UIView!
    
    @IBOutlet weak private var badgeImageView: GIFImageView!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var alternateTimestampLabel: UILabel!
    @IBOutlet weak private var lhsImageView: GIFImageView!
    @IBOutlet weak private var lhsImageWidth: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageHeight: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageCenterAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageTopAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageBottomAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageLeadingMargin: NSLayoutConstraint!
    
    // padding
    @IBOutlet var timestampLabelTrailingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var timestampLabelToBadgePaddingConstraint: NSLayoutConstraint!
    @IBOutlet var alternateTimestampLeadingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var alternateTimestampTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var alternateTimestampBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak private var messageLeadPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var messageTrailingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var usernameLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var usernameTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak private var messageBodyTrailingToSafeArea: NSLayoutConstraint!
    @IBOutlet weak private var messageBodyBottomMargin: NSLayoutConstraint!
    @IBOutlet weak private var messageBodyTopMargin: NSLayoutConstraint!
    
    lazy var reactionsDisplayView = constraintBased { ReactionsDisplayView() }
    
    // MARK: - Internal Properties

    weak var actionsDelegate: ChatActionsDelegate?

    var state: State = .normal {
        didSet {
            switch (oldValue, state) {
            case (.normal, .showingActionsPanel):
                showActionsPanel()
            case (.showingActionsPanel, .normal):
                hideActionsPanel()
            default:
                break
            }
        }
    }
    
    var theme: Theme = Theme()

    // MARK: - Private Properties
    private var isLocalClientMessage: Bool = false
    private var message: MessageViewModel?
    private let badgePadding: CGFloat = 16.0 // 14pt for badge + 2pt for leading
    private let timestampPadding: CGFloat = 2.0
    private var badgeExists: Bool = false
    private var cellImageUrl: URL?
    private var timestampExists: Bool = false
    private weak var tableView: UITableView?
    private var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if reactionsDisplayView.superview == nil {
            addSubview(reactionsDisplayView)
            
            let xInset = theme.chatCornerRadius + 3
            
            NSLayoutConstraint.activate([
                reactionsDisplayView.centerYAnchor
                    .constraint(equalTo: messageViewHolder.topAnchor, constant: theme.messageReactionsVerticalOffset),
                reactionsDisplayView.rightAnchor
                    .constraint(equalTo: messageViewHolder.rightAnchor, constant: -(xInset)),
                reactionsDisplayView.leftAnchor
                    .constraint(greaterThanOrEqualTo: messageViewHolder.leftAnchor, constant: xInset)
            ])
        }
    }

    // MARK: - Configuration Functions

    func configure(
        for message: MessageViewModel,
        indexPath: IndexPath,
        timestampFormatter: TimestampFormatter?,
        shouldDisplayDebugVideoTime: Bool
    ) {
        self.message = message
        isLocalClientMessage = message.isLocalClient
        hideActionsPanel()

        timestampExists = timestampFormatter != nil
        usernameLabel.text = message.username
        //timestampLabel.text = timestampFormatter?(message.createdAt)
        timestampLabel.text = nil // using alternateTimestamp label only for now
        
        alternateTimestampLabel.text = {
            
            let defaultTimestamp = timestampFormatter?(message.createdAt)
            if shouldDisplayDebugVideoTime {
                var debugTimestamp = ""
                if let defaultTimestamp = defaultTimestamp {
                    debugTimestamp = "Created: \(defaultTimestamp)"
                }
                
                if let videoTime = message.videoPlayerDebugTime {
                    if let videoTimeCode = timestampFormatter?(videoTime){
                        debugTimestamp.append(" | Sync Time: \(videoTimeCode)")
                    }
                }
                return debugTimestamp
            }
            return defaultTimestamp
            
        }()
        
        if let imageUrl = message.badgeImageURL {
            badgeImageView.setImage(key: imageUrl.absoluteString)
            self.badgeExists = true
        } else {
            self.badgeExists = false
        }
                
        reactionsDisplayView.set(chatReactions: message.chatReactions, theme: theme)
        
        cellImageUrl = message.profileImageUrl
        
        applyTheme()
    }

    func applyTheme() {
        updateAttributedTextStyles(theme: theme)
        timestampLabel.font = theme.chatMessageTimestampFont
        timestampLabel.textColor = theme.chatMessageTimestampTextColor
        alternateTimestampLabel.font = theme.chatMessageTimestampFont
        alternateTimestampLabel.textColor = theme.chatMessageTimestampTextColor
        messageViewHolder.layer.cornerRadius = theme.messageCornerRadius
        messageBackground.backgroundColor = theme.messageBackgroundColor
        messageBackground.layer.cornerRadius = theme.messageCornerRadius
        messageLabel.font = theme.fontPrimary
        messageLabel.textColor = theme.messageTextColor
        usernameLabel.textColor = isLocalClientMessage ? theme.myUsernameTextColor : theme.usernameTextColor
        usernameLabel.font = theme.fontSecondary
        timestampLabelTrailingPaddingConstraint?.constant = theme.messageMargins.right
        timestampLabelToBadgePaddingConstraint?.constant = badgeExists ? theme.messagePadding : theme.messagePadding - badgePadding
        alternateTimestampLeadingPaddingConstraint?.constant = theme.messagePadding
        alternateTimestampTopPaddingConstraint?.constant = theme.chatMessageTimestampTopPadding
        messageLeadPaddingConstraint.constant = theme.messagePadding
        messageTrailingPaddingConstraint.constant = theme.messagePadding
        usernameLeadingConstraint?.constant = theme.messagePadding
        usernameTrailingConstraint?.constant = {
            var constant = theme.messagePadding
            if badgeExists {
                constant += badgePadding
            }
            return constant
        }()

        timestampLabelToBadgePaddingConstraint?.isActive = timestampExists
        timestampLabelTrailingPaddingConstraint?.isActive = timestampExists
        alternateTimestampLeadingPaddingConstraint?.isActive = timestampExists
        alternateTimestampBottomConstraint?.isActive = timestampExists

        let usernameRowWidth: CGFloat = {
            var width = usernameLabel.intrinsicContentSize.width
            if badgeExists {
                width += badgePadding
            }
            width += timestampLabel.intrinsicContentSize.width
            return width
        }()
        if usernameRowWidth > messageLabel.intrinsicContentSize.width {

            usernameTrailingConstraint?.constant += timestampLabel.intrinsicContentSize.width
            usernameTrailingConstraint?.isActive = true
            messageTrailingPaddingConstraint.isActive = false
        } else {
            usernameTrailingConstraint?.isActive = false
            messageTrailingPaddingConstraint.isActive = true
        }
        
        if theme.chatImageWidth > 0 {
            if let imageUrl = cellImageUrl?.absoluteString {
                lhsImageView.setImage(key: imageUrl)
            }
        }
        lhsImageWidth.constant = theme.chatImageWidth
        
        if theme.chatImageWidth > 0 {
            lhsImageHeight.constant = theme.chatImageHeight
            lhsImageView.livelike_cornerRadius = theme.chatImageCornerRadius
            lhsImageLeadingMargin.constant = -theme.messageMargins.left
        }
        
        messageViewHolderLeading.constant = theme.chatImageWidth + theme.chatImageTrailingMargin + theme.messageMargins.left
        
        switch theme.chatImageVerticalAlignment {
        case .top:
            lhsImageTopAlignment.isActive = true
            lhsImageTopAlignment.constant = -(theme.messageTopBorderHeight + theme.messageMargins.top)
            lhsImageCenterAlignment.isActive = false
            lhsImageBottomAlignment.isActive = false
            
        case .center:
            lhsImageTopAlignment.isActive = false
            lhsImageCenterAlignment.isActive = true
            lhsImageBottomAlignment.isActive = false
        case .bottom:
            lhsImageTopAlignment.isActive = false
            lhsImageCenterAlignment.isActive = false
            lhsImageBottomAlignment.isActive = true
        }
        
        reactionsDisplayView.setTheme(theme)
        
        if theme.messageDynamicWidth {
            messageBodyTrailingToSafeArea.isActive = false
            usernameTrailingConstraint?.isActive = true
        } else {
            messageBodyTrailingToSafeArea.isActive = true
            usernameTrailingConstraint?.isActive = false
        }
         
        messageBodyTopMargin.constant = theme.messageMargins.top + theme.messageTopBorderHeight
        messageBodyBottomMargin.constant = theme.messageMargins.bottom + theme.messageBottomBorderHeight
        
        topBorder.backgroundColor = theme.messageTopBorderColor
        topBorderHeight.constant = theme.messageTopBorderHeight
        bottomBorder.backgroundColor = theme.messageBottomBorderColor
        bottomBorderHeight.constant = theme.messageBottomBorderHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageViewHolder.layer.cornerRadius = theme.messageCornerRadius
    }

    private func updateAttributedTextStyles(theme: Theme) {
        guard let message = self.message else {
            return
        }
        messageLabel.attributedText = message.attributedMessage(theme: theme)
    }
}

// MARK: - Actions Panel show/hide

internal extension ChatMessageView {
    enum State {
        case normal
        case showingActionsPanel
    }

    func showActionsPanel() {
        messageBackground.backgroundColor = theme.messageSelectedColor
    }

    func hideActionsPanel() {
        messageBackground.backgroundColor = theme.messageBackgroundColor
    }
}

// MARK: - Protocol conformances

extension ChatMessageView: Selectable {
    var isSelected: Bool {
        get { return state == .showingActionsPanel }
        set {
            state = newValue ? .showingActionsPanel : .normal
        }
    }
}

extension ChatMessageView: ChatActionsDelegateContainer {}
