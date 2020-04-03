//
//  ReactionsDisplayView.swift
//  EngagementSDK
//

import UIKit

class ReactionsDisplayView: UIView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()

    private let reactionCountLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = "reactionCountLabel"
        return view
    }()
    private var reactionImageViewsByID: [String: UIImageView] = [:]
    private let customSpacingAfterLastReaction = CGFloat(3.0)
    
    init() {
        super.init(frame: .zero)
        stackView.addArrangedSubview(reactionCountLabel)
        addSubview(stackView)
        stackView.constraintsFill(to: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private let reactionHintID = ReactionID(fromString: "LLReactionHint")
    private var theme: Theme?
    lazy private var reactionHint: ReactionButtonViewModel? = {
        
        // if theme.reactionsImageHint == nil then the integrator
        // decided to turn off reaction hint
        if let reactionsHintImage = theme?.reactionsImageHint {
            return ReactionButtonViewModel(id: reactionHintID,
                                               voteCount: 0,
                                               isMine: false,
                                               myVoteID: nil,
                                               image: reactionsHintImage,
                                               name: "Reaction Hint")
        }
        return nil
    }()

    private func makeImageView(for chatReaction: ReactionButtonViewModel) -> UIImageView {
        let imageView = constraintBased {
            UIImageView(image: chatReaction.image)
        }

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 12.0),
            imageView.heightAnchor.constraint(equalToConstant: 12.0),
            ])

        return imageView
    }

    private func setReactionCount(_ count: Int){
        guard count > 0 else {
            reactionCountLabel.text = nil
            return
        }

        reactionCountLabel.text = NumberFormatter.localizedString(
            from: NSNumber(value: count),
            number: .decimal)

        adjustReactionLabelSpacing()
    }

    private func adjustReactionLabelSpacing(){
        guard let reactionLabelIndex = stackView.arrangedSubviews.firstIndex(of: reactionCountLabel) else { return }
        guard let viewAfterReactionLabel = stackView.arrangedSubviews[safe: reactionLabelIndex - 1] else { return }
            stackView.osAdaptive_setCustomSpacing(
                customSpacingAfterLastReaction,
                after: viewAfterReactionLabel)
        }
}

internal extension ReactionsDisplayView {
    func set(chatReactions: ReactionButtonListViewModel, theme: Theme) {
        self.theme = theme
        
        // check if chatroom supports reactions
        guard chatReactions.reactions.count > 0 else {
            return
        }
        
        guard chatReactions.totalReactionsCount > 0 else {
            // add reactions hint image if enabled
            if let reactionHint = reactionHint {
                addReactionToStack(reactionModelView: reactionHint)
            }
            return
        }
        
        chatReactions.reactions.forEach { reaction in
            guard chatReactions.voteCount(forID: reaction.id) > 0 else { return }
            if reactionImageViewsByID[reaction.id.asString] == nil {
                addReactionToStack(reactionModelView: reaction)
            }
        }
        setReactionCount(chatReactions.totalReactionsCount)
    }

    func update(chatReactions: ReactionButtonListViewModel) {
        
        // remove Reactions Hint
        if let reactionHintImageView = reactionImageViewsByID[reactionHintID.asString] {
            if chatReactions.totalReactionsCount > 0 {
                reactionHintImageView.isHidden = true
                stackView.removeArrangedSubview(reactionHintImageView)
                reactionImageViewsByID.removeValue(forKey: reactionHintID.asString)
            }
        }
        
        chatReactions.reactions.forEach { reaction in
            if let imageView = reactionImageViewsByID[reaction.id.asString] {
                //update count - hide reaction image view if new count is 0
                if chatReactions.voteCount(forID: reaction.id) == 0 {
                    imageView.isHidden = true
                    stackView.removeArrangedSubview(imageView)
                    reactionImageViewsByID.removeValue(forKey: reaction.id.asString)
                    
                    if chatReactions.totalReactionsCount == 0 {
                        if let reactionHint = reactionHint {
                            addReactionToStack(reactionModelView: reactionHint)
                        }
                    }
                }
            } else {
                guard chatReactions.voteCount(forID: reaction.id) > 0 else { return }
                //insert new reaction image view
                addReactionToStack(reactionModelView: reaction, animated: true)
            }
        }
        setReactionCount(chatReactions.totalReactionsCount)
    }
    
    func setTheme(_ theme: Theme) {
        reactionCountLabel.font = theme.fontSecondary.withSize(10.0)
        reactionCountLabel.textColor = theme.chatReactions.displayCountsColor
    }
    
    func addReactionToStack(reactionModelView: ReactionButtonViewModel) {
        addReactionToStack(reactionModelView: reactionModelView, animated: false)
    }
    
    func addReactionToStack(reactionModelView: ReactionButtonViewModel, animated: Bool) {
        let newImageView = makeImageView(for: reactionModelView)
        stackView.insertArrangedSubview(newImageView, at: 0)
        reactionImageViewsByID[reactionModelView.id.asString] = newImageView
        
        if animated {
            newImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
            firstly {
                UIView.animate(duration: 0.3, animations: {
                    newImageView.isHidden = false
                })
            }.then { _ in
                UIView.animatePromise(
                    withDuration: 1.2,
                    delay: 0,
                    usingSpringWithDamping: 0.3,
                    initialSpringVelocity: 0,
                    options: .curveEaseInOut) {
                        newImageView.transform = .identity
                }
            }.catch {
                log.error($0.localizedDescription)
            }
        }
    }
}

// Adapted from https://stackoverflow.com/a/53934631
fileprivate extension UIStackView {
    func osAdaptive_setCustomSpacing(_ spacing: CGFloat, after arrangedSubview: UIView) {
        if #available(iOS 11.0, *) {
            self.setCustomSpacing(spacing, after: arrangedSubview)
        } else {
            guard let index = self.arrangedSubviews.firstIndex(of: arrangedSubview) else {
                return
            }
            
            let separatorView = UIView(frame: .zero)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            switch axis {
            case .horizontal:
                separatorView.widthAnchor.constraint(equalToConstant: spacing).isActive = true
            case .vertical:
                separatorView.heightAnchor.constraint(equalToConstant: spacing).isActive = true
            @unknown default:
                log.verbose("Didn't handle new case for 'axis', this message was thought to only be to silence a warning, but I guess 🍏 is making 3D displays now or something 🤷🏽‍♂️")
            }
            
            insertArrangedSubview(separatorView, at: index + 1)
        }
    }
}
