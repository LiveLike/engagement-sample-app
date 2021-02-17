//
//  ChatMessageCell.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-19.
//

import UIKit

class ChatMessageView: UIView {
    // MARK: - Outlets

    @IBOutlet weak var messageLabel: AnimatedLabel!
    
    @IBOutlet weak private var topBorder: UIView!
    @IBOutlet weak private var topBorderHeight: NSLayoutConstraint!
    @IBOutlet weak private var bottomBorder: UIView!
    @IBOutlet weak private var bottomBorderHeight: NSLayoutConstraint!
    
    @IBOutlet weak private var messageViewHolderLeading: NSLayoutConstraint!
    @IBOutlet weak private var usernameLabel: UILabel!
    @IBOutlet weak private var messageViewHolder: UIView!
    @IBOutlet weak private var messageBackground: UIView!
    
    @IBOutlet weak private var badgeImageView: GIFImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var alternateTimestampLabel: UILabel!
    @IBOutlet weak private var lhsImageView: GIFImageView!
    @IBOutlet weak private var lhsImageWidth: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageHeight: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageCenterAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageTopAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageBottomAlignment: NSLayoutConstraint!
    @IBOutlet weak private var lhsImageLeadingMargin: NSLayoutConstraint!
    
    // padding
    @IBOutlet weak var timestampLabelTrailingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var timestampLabelToBadgePaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var alternateTimestampLeadingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var alternateTimestampTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var alternateTimestampBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak private var messageLeadPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var messageTrailingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var usernameLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var usernameTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak private var messageBodyTrailingToSafeArea: NSLayoutConstraint!
    @IBOutlet weak private var messageBodyBottomMargin: NSLayoutConstraint!
    @IBOutlet weak private var messageBodyTopMargin: NSLayoutConstraint!
    
    lazy var reactionsDisplayView = constraintBased { ReactionsDisplayView() }

    var reactionHintImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
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
    private var cellImageUrl: URL?
    private var timestampExists: Bool = false
    private var shouldDisplayAvatar: Bool = false
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if reactionsDisplayView.superview == nil {
            addSubview(reactionsDisplayView)
            addSubview(reactionHintImageView)
            
            let xInset = theme.chatCornerRadius + 3
            
            var reactionsVerticalAlignment: NSLayoutYAxisAnchor
            switch theme.messageReactionsVerticalAlignment {
            case .top:
                reactionsVerticalAlignment = messageViewHolder.topAnchor
            case .center:
                reactionsVerticalAlignment = messageViewHolder.centerYAnchor
            case .bottom:
                reactionsVerticalAlignment = messageViewHolder.bottomAnchor
            }
            
            NSLayoutConstraint.activate([
                reactionsDisplayView.centerYAnchor
                    .constraint(equalTo: reactionsVerticalAlignment, constant: theme.messageReactionsVerticalOffset),
                reactionsDisplayView.rightAnchor
                    .constraint(equalTo: messageViewHolder.rightAnchor, constant: -(xInset)),
                reactionsDisplayView.leftAnchor
                    .constraint(greaterThanOrEqualTo: messageViewHolder.leftAnchor, constant: xInset),

                reactionHintImageView.centerYAnchor
                    .constraint(equalTo: reactionsVerticalAlignment, constant: theme.messageReactionsVerticalOffset),
                reactionHintImageView.rightAnchor
                    .constraint(equalTo: messageViewHolder.rightAnchor, constant: -(xInset)),
                reactionHintImageView.leftAnchor
                    .constraint(greaterThanOrEqualTo: messageViewHolder.leftAnchor, constant: xInset),
                reactionHintImageView.heightAnchor.constraint(equalToConstant: 12),
                reactionHintImageView.widthAnchor.constraint(equalToConstant: 12),
            ])
        }
    }

    // MARK: - Configuration Functions

    func configure(
        for message: MessageViewModel,
        indexPath: IndexPath,
        timestampFormatter: TimestampFormatter?,
        shouldDisplayDebugVideoTime: Bool,
        shouldDisplayAvatar: Bool,
        theme: Theme
    ) {
        self.theme = theme
        self.message = message
        
        self.isLocalClientMessage = message.isLocalClient
        self.shouldDisplayAvatar = shouldDisplayAvatar
        self.hideActionsPanel()
        
        self.messageLabel.attributedText = message.message
        self.timestampExists = timestampFormatter != nil
        self.usernameLabel.text = message.username
        //timestampLabel.text = timestampFormatter?(message.createdAt)
        self.timestampLabel.text = nil // using alternateTimestamp label only for now
        
        self.alternateTimestampLabel.text = {
            
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
                
        self.reactionsDisplayView.set(chatReactions: message.chatReactions, theme: self.theme)
        self.reactionHintImageView.isHidden = message.chatReactions.totalReactionsCount != 0
        
        self.cellImageUrl = message.profileImageUrl
        self.accessibilityLabel = message.accessibilityLabel
        
        // Handle Chat Avatar
        if self.shouldDisplayAvatar {
            lhsImageView.isHidden = false
            if let imageUrl = cellImageUrl {
                lhsImageView.setImage(url: imageUrl)
            }
        } else {
            lhsImageView.isHidden = true
        }
        
        self.applyTheme()
    }
    
    func applyTheme() {
        timestampLabel.font = theme.chatMessageTimestampFont
        timestampLabel.textColor = theme.chatMessageTimestampTextColor
        alternateTimestampLabel.font = theme.chatMessageTimestampFont
        alternateTimestampLabel.textColor = theme.chatMessageTimestampTextColor
        alternateTimestampLabel.text = theme.chatMessageTimestampUppercased ? alternateTimestampLabel.text?.uppercased() : alternateTimestampLabel.text
        messageViewHolder.layer.cornerRadius = theme.messageCornerRadius
        messageBackground.backgroundColor = theme.messageBackgroundColor
        messageBackground.layer.cornerRadius = theme.messageCornerRadius
        messageLabel.textColor = theme.messageTextColor
        usernameLabel.textColor = isLocalClientMessage ? theme.myUsernameTextColor : theme.usernameTextColor
        usernameLabel.font = theme.usernameTextFont
        usernameLabel.text = theme.usernameTextUppercased ? usernameLabel.text?.uppercased() : usernameLabel.text
        timestampLabelTrailingPaddingConstraint?.constant = theme.messageMargins.right
        timestampLabelToBadgePaddingConstraint?.constant = theme.messagePadding - badgePadding
        alternateTimestampLeadingPaddingConstraint?.constant = theme.messagePadding
        alternateTimestampTopPaddingConstraint?.constant = theme.chatMessageTimestampTopPadding
        messageLeadPaddingConstraint.constant = theme.messagePadding
        messageTrailingPaddingConstraint.constant = theme.messagePadding
        usernameLeadingConstraint?.constant = theme.messagePadding
        usernameTrailingConstraint?.constant = theme.messagePadding

        timestampLabelToBadgePaddingConstraint?.isActive = timestampExists
        timestampLabelTrailingPaddingConstraint?.isActive = timestampExists
        alternateTimestampLeadingPaddingConstraint?.isActive = timestampExists
        alternateTimestampBottomConstraint?.isActive = timestampExists

        let usernameRowWidth: CGFloat = {
            var width = usernameLabel.intrinsicContentSize.width
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
        
        // Handle Chat Avatar
        if self.shouldDisplayAvatar {
            lhsImageWidth.constant = theme.chatImageWidth
            
            if theme.chatImageWidth > 0 {
                lhsImageHeight.constant = theme.chatImageHeight
                lhsImageView.livelike_cornerRadius = theme.chatImageCornerRadius
                lhsImageLeadingMargin.constant = -theme.messageMargins.left
            }
            
            messageViewHolderLeading.constant = theme.chatImageWidth + theme.chatImageTrailingMargin + theme.messageMargins.left
        } else {
            messageViewHolderLeading.constant = theme.messageMargins.left
        }
        
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

        reactionHintImageView.image = theme.reactionsImageHint
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageViewHolder.layer.cornerRadius = theme.messageCornerRadius
    }
    
    func prepareForReuse() {
        message = nil
        messageLabel.prepareForReuse()
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
    // swiftlint:disable implicit_getter
    var isSelected: Bool {
        get { return state == .showingActionsPanel }
        set {
            state = newValue ? .showingActionsPanel : .normal
        }
    }
}

extension ChatMessageView: ChatActionsDelegateContainer {}
