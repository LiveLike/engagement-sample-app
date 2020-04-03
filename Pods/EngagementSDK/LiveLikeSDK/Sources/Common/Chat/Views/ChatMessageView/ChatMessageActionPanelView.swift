//
//  ReactionsView.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 9/10/19.
//

import Foundation
import UIKit

protocol ChatMessageActionPanelDelegate: AnyObject {
    func chatMessageReactionSelected(for messageViewModel: MessageViewModel, reaction: ReactionID)
    func chatFlagButtonPressed(for messageViewModel: MessageViewModel)
}

enum ChatMessageActionPanelAnimationDirection {
    case up
    case down
}

class ChatMessageActionPanelView: UIStackView {
    static let defaultCornerRadius: CGFloat = 12.0
    
    private let debug: Bool = false
    private var reactionFocusBgCenterX: NSLayoutConstraint?
    private var theme: Theme = Theme()
    
    weak var chatMessageActionPanelDelegate: ChatMessageActionPanelDelegate?
    var messageViewModel: MessageViewModel?
    
    private let reactionsHolder: UIStackView = {
        let stackView: UIStackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 0.0
        stackView.addPadding(viewInsets: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let flagHolder: UIStackView = {
        let stackView: UIStackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.addPadding(viewInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        stackView.alignment = .center
        return stackView
    }()
    
    private let flagBtn: UIButton = {
        let flagBtn = UIButton(frame: .zero)
        flagBtn.setImage(UIImage(named: "chat_flag", in: Bundle(for: EngagementSDK.self), compatibleWith: nil), for: .normal)
        flagBtn.translatesAutoresizingMaskIntoConstraints = false
        flagBtn.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        flagBtn.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        flagBtn.addTarget(self, action: #selector(chatFlagPressed(sender:)), for: .touchUpInside)
        return flagBtn
    }()

    private var reactionsBackgroundView: UIView = UIView()
    private var flagBackgroundView: UIView = UIView()
    
    @objc private func chatReactionPressed(sender: UITapGestureRecognizer!) {
        if let reactionView  = sender.view as? ReactionView {
            UIAccessibility.post(notification: .layoutChanged, argument: reactionView)
            resetReactionsFocus { [weak self] in
                guard let self = self else { return }
                reactionView.isMine = true
                if let messageViewModel = self.messageViewModel {
                    self.chatMessageActionPanelDelegate?.chatMessageReactionSelected(
                        for: messageViewModel,
                        reaction: reactionView.reactionID
                    )
                }
            }
        }
    }
    
    @objc private func chatFlagPressed(sender: UIButton) {
        if let messageViewModel = messageViewModel {
            chatMessageActionPanelDelegate?.chatFlagButtonPressed(for: messageViewModel)
        }
    }

    init(){
        super.init(frame: .zero)
        self.addArrangedSubview(reactionsHolder)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public
extension ChatMessageActionPanelView {
    func setUp(reactions: ReactionButtonListViewModel){
        self.spacing = 8.0
        setUpReactionsStack(reactions: reactions)
        setUpFlagHolder()
        
        reactionsBackgroundView.livelike_shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        reactionsBackgroundView.livelike_shadowOpacity = 0.3
        reactionsBackgroundView.livelike_shadowRadius = 3
        reactionsBackgroundView.livelike_shadowOffset = CGSize(width: 0, height: 0)
        
        flagBackgroundView.livelike_shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        flagBackgroundView.livelike_shadowOpacity = 0.3
        flagBackgroundView.livelike_shadowRadius = 3
        flagBackgroundView.livelike_shadowOffset = CGSize(width: 0, height: 0)
    }
    
    func prepareToBeShown(messageViewModel: MessageViewModel) {
        self.messageViewModel = messageViewModel

        reactionsHolder.arrangedSubviews.forEach { view in
            guard let reactionView = view as? ReactionView else { return }
            let count = messageViewModel
                    .chatReactions
                    .voteCount(forID: reactionView.reactionID)
            reactionView.setCount(count)
            
            reactionView.isMine = messageViewModel.chatReactions.isMine(forID: reactionView.reactionID)
        }

        flagHolder.isHidden = !messageViewModel.isReportable
        
    }
    
    func setTheme(theme: Theme) {
        self.theme = theme
        reactionsBackgroundView.backgroundColor = theme.reactionsPopupBackground
        flagBackgroundView.backgroundColor = theme.reactionsPopupBackground
        flagBtn.tintColor = theme.chatDetailSecondaryColor
        reactionsBackgroundView = reactionsHolder.addBackground(
            color: .clear,
            cornerRadius: theme.reactionsPopupCornerRadius)
        flagBackgroundView = flagHolder.addBackground(
            color: .clear,
            cornerRadius: theme.reactionsPopupCornerRadius)
    }
    
    func reset() {
        resetReactionsFocus(completion: nil)
        messageViewModel = nil
    }
}

// MARK: - Private
private extension ChatMessageActionPanelView {
    func setUpReactionsStack(reactions: ReactionButtonListViewModel) {
        guard reactions.reactions.count > 0 else {
            reactionsHolder.isHidden = true
            return
        }
        reactionsHolder.isHidden = false
        reactionsHolder.removeAllArrangedSubviews()
        addElementsToStack(reactions: reactions)
    }
    
    func resetReactionsFocus(completion: (() -> Void)?) {
        reactionsHolder.arrangedSubviews.forEach { possibleReactionView in
            if let reactionView = possibleReactionView as? ReactionView {
                reactionView.isMine = false
            }
        }
        completion?()
    }
    
    func setUpFlagHolder() {
        flagHolder.addArrangedSubview(flagBtn)
        self.addArrangedSubview(flagHolder)
    }
    
    func addElementsToStack(reactions: ReactionButtonListViewModel) {
        reactions.reactions.enumerated().forEach { index, reaction in
            let reactionView = ReactionView(reactionID: reaction.id,
                                            emoji: reaction.image,
                                            reactionCount: reaction.voteCount,
                                            name: reaction.name)
            reactionView.tag = index
            reactionView.translatesAutoresizingMaskIntoConstraints = false
            let tap = UITapGestureRecognizer(target: self, action: #selector(chatReactionPressed(sender:)))
            reactionView.setTheme(self.theme)
            reactionView.addGestureRecognizer(tap)
            NSLayoutConstraint.activate([
                reactionView.widthAnchor.constraint(greaterThanOrEqualToConstant: 34.0)
            ])
            reactionsHolder.addArrangedSubview(reactionView)
        }
    }
}

extension UIStackView {
    func removeAllArrangedSubviews(){
        while let arrangedSubview = self.arrangedSubviews.first {
            self.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }
}
