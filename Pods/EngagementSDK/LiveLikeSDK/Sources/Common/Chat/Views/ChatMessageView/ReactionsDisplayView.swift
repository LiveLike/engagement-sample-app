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
    private let mediaRepository = EngagementSDK.mediaRepository
    
    init() {
        super.init(frame: .zero)
        stackView.addArrangedSubview(reactionCountLabel)
        addSubview(stackView)
        stackView.constraintsFill(to: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme = Theme()

    private func makeImageView(for chatReaction: ReactionButtonViewModel) -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false

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
        stackView.arrangedSubviews.forEach({
            stackView.osAdaptive_setCustomSpacing(theme.messageReactionsSpaceBetweenIcons, after: $0)
        })
        
        guard let reactionLabelIndex = stackView.arrangedSubviews.firstIndex(of: reactionCountLabel) else { return }
        guard let viewAfterReactionLabel = stackView.arrangedSubviews[safe: reactionLabelIndex - 1] else { return }
        stackView.osAdaptive_setCustomSpacing(theme.messageReactionsCountLeadingMargin, after: viewAfterReactionLabel)
    }
    
}

internal extension ReactionsDisplayView {
    func set(chatReactions: ReactionButtonListViewModel, theme: Theme) {
        self.theme = theme
        
        // check if chatroom supports reactions
        guard chatReactions.reactions.count > 0 else {
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
        chatReactions.reactions.forEach { reaction in
            if let imageView = reactionImageViewsByID[reaction.id.asString] {
                //update count - hide reaction image view if new count is 0
                if chatReactions.voteCount(forID: reaction.id) == 0 {
                    imageView.isHidden = true
                    stackView.removeArrangedSubview(imageView)
                    reactionImageViewsByID.removeValue(forKey: reaction.id.asString)
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
        reactionCountLabel.font = theme.reactionsPopupCountFont
        reactionCountLabel.textColor = theme.chatReactions.displayCountsColor

        adjustReactionLabelSpacing()
    }
    
    func addReactionToStack(reactionModelView: ReactionButtonViewModel) {
        addReactionToStack(reactionModelView: reactionModelView, animated: false)
    }
    
    func addReactionToStack(reactionModelView: ReactionButtonViewModel, animated: Bool) {
        let newImageView = makeImageView(for: reactionModelView)
        stackView.insertArrangedSubview(newImageView, at: 0)
        reactionImageViewsByID[reactionModelView.id.asString] = newImageView
        
        if animated {
            mediaRepository.getImage(url: reactionModelView.imageURL) { result in
                switch result {
                case .success(let imageResult):
                    newImageView.image = imageResult.image
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

                case .failure(let error):
                    log.error(error.localizedDescription)
                }
            }
        } else {
            mediaRepository.getImage(url: reactionModelView.imageURL) { result in
                switch result {
                case .success(let imageResult):
                    newImageView.image = imageResult.image
                case .failure(let error):
                    log.error(error.localizedDescription)
                }
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
