//
//  MessagesViewController.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-08.
//

import UIKit

class MessageViewController: UIViewController {
    // Public Properties
    public weak var chatAdapter: ChatAdapter? {
        didSet {
            tableView.dataSource = chatAdapter
            chatAdapter?.tableView = tableView
            chatAdapter?.actionsDelegate = self
            self.dismissChatMessageActionPanel()
        }
    }

    // MARK: - Internal Properties

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    var tableTrailingConstraint: NSLayoutConstraint?
    var tableLeadingConstraint: NSLayoutConstraint?
    var chatMessageActionPanelViewTopAnchor: NSLayoutConstraint?

    lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.frame = tableView.superview?.bounds ?? .zero
        gradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0.0, 0.0, 0.1, 0.95, 1.0]
        tableView.superview?.layer.mask = gradient
        return gradient
    }()

    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let chatMessageActionPanelView: ChatMessageActionPanelView = {
        let view = ChatMessageActionPanelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = .zero
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Reactions Panel Opened"
        view.accessibilityTraits = .allowsDirectInteraction
        return view
    }()
    
    private var initialActionPanelTopAnchor: CGFloat = 0.0
    private var theme: Theme = Theme()
    
    private var emptyChatCustomView: UIView?

    weak var session: InternalContentSession? {
        didSet {
            guard let session = session else { return }
            firstly {
                session.reactionsVendor.getReactions()
            }.then { reactions in
                session.reactionsViewModelFactory.make(from: reactions)
            }.then { [weak self] reactionsViewModel in
                self?.chatMessageActionPanelView.setUp(reactions: reactionsViewModel)
            }.catch {
                log.error($0.localizedDescription)
            }
        }
    }

    /// Used to prevent the user from spamming reactions before receiving and update from the server
    private var canReact: Bool = true

    // MARK: - Initializers

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = tableView.superview?.bounds ?? .null
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        setupActivityIndicator()
        setupTableView()
        chatMessageActionPanelView.chatMessageActionPanelDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardDidShow(){
        tableView.allowsSelection = false
    }

    @objc private func keyboardDidHide(){
        tableView.allowsSelection = true
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(chatMessageActionPanelView)

        tableLeadingConstraint = tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.chatLeadingMargin)
        tableTrailingConstraint = view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: theme.chatTrailingMargin)
        chatMessageActionPanelViewTopAnchor = chatMessageActionPanelView.topAnchor.constraint(equalTo: view.topAnchor)
        var constraints = [
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableLeadingConstraint!,
            tableTrailingConstraint!,
            
            chatMessageActionPanelView.widthAnchor.constraint(greaterThanOrEqualToConstant: 46.0),
            chatMessageActionPanelView.heightAnchor.constraint(equalToConstant: 36.0),
            chatMessageActionPanelViewTopAnchor!
        ]

        switch theme.reactionsPopupHorizontalAlignment {
        case .left:
            constraints.append(chatMessageActionPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.reactionsPopupHorizontalOffset))
        case .center:
            constraints.append(chatMessageActionPanelView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: theme.reactionsPopupHorizontalOffset))
        case .right:
            constraints.append(chatMessageActionPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: theme.reactionsPopupHorizontalOffset))
        }
        
        NSLayoutConstraint.activate(constraints)

        tableView.dataSource = chatAdapter
    }

    func isLoading(_ loading: Bool) {
        if loading {
            view.bringSubviewToFront(activityIndicator)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    public func setTheme(_ theme: Theme) {
        self.theme = theme
        tableLeadingConstraint?.constant = theme.chatLeadingMargin
        tableTrailingConstraint?.constant = theme.chatTrailingMargin
        chatMessageActionPanelView.setTheme(theme: theme)

        self.emptyChatCustomView?.removeFromSuperview()
        if let newEmptyChatCustomView = theme.emptyChatCustomView {
            newEmptyChatCustomView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(newEmptyChatCustomView, at: 0)
            newEmptyChatCustomView.constraintsFill(to: view)
            // use the hidden state of previous emptyChatCustomView
            newEmptyChatCustomView.isHidden = self.emptyChatCustomView?.isHidden ?? true
        }
        self.emptyChatCustomView = theme.emptyChatCustomView
    }

    func expandGradientOverlay(height: CGFloat?) {
        guard let height = height else { return }
        let heightWithPadding = height + CGFloat(8)
        let sizeInPercentage = Float(heightWithPadding / view.bounds.height)
        gradientLayer.locations = [0.0, NSNumber(value: sizeInPercentage), NSNumber(value: sizeInPercentage + 0.1), 0.95, 1.0]
    }

    func shrinkGradientOverlay() {
        gradientLayer.locations = [0.0, 0.0, 0.1, 0.95, 1.0]
    }
    
    private func updateNoMessagesCustomView(messageCount: Int){
        self.emptyChatCustomView?.isHidden = messageCount > 0
    }
    
}

// MARK: - ChatActionsDelegate

extension MessageViewController: ChatActionsDelegate {
    var actionPanelHeight: CGFloat {
        return chatMessageActionPanelView.bounds.height + theme.reactionsPopupVerticalOffset + 20
    }

    func chatAdapter(_ chatAdapter: ChatAdapter, messageCountDidChange count: Int) {
        self.updateNoMessagesCustomView(messageCount: count)
    }

    func actionPanelPrepareToBeShown(messageViewModel: MessageViewModel) {
        // only update if it is the same view model
        guard chatMessageActionPanelView.messageViewModel?.id == messageViewModel.id else { return }
        chatMessageActionPanelView.prepareToBeShown(messageViewModel: messageViewModel)
    }

    func showChatMessageActionPanel(for messageViewModel: MessageViewModel,
                                    cellRect: CGRect,
                                    direction: ChatMessageActionPanelAnimationDirection) {
        guard let actionPanelTopAnchor = chatMessageActionPanelViewTopAnchor else { return }
        
        chatMessageActionPanelView.alpha = 0.0
        actionPanelTopAnchor.constant = cellRect.origin.y - 20 - theme.reactionsPopupVerticalOffset
        initialActionPanelTopAnchor = cellRect.origin.y - 20 - theme.reactionsPopupVerticalOffset
        
        chatMessageActionPanelView.reset()
        guard let newMessageViewModel = chatAdapter?.getMessage(withID: messageViewModel.id) else { return }

        chatMessageActionPanelView.prepareToBeShown(messageViewModel: newMessageViewModel)
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            actionPanelTopAnchor.constant = direction == .up ? cellRect.origin.y - 44.0 - self.theme.reactionsPopupVerticalOffset : cellRect.origin.y + cellRect.size.height + self.theme.reactionsPopupVerticalOffset
            self.chatMessageActionPanelView.alpha = 1.0
            self.view.layoutIfNeeded()
            self.chatAdapter?.recordChatReactionPanelOpened(for: messageViewModel)
            UIAccessibility.post(notification: .layoutChanged, argument: self.chatMessageActionPanelView)
        }
    }
    
    func dismissChatMessageActionPanel() {
        guard let reactionsViewTopConstraint = chatMessageActionPanelViewTopAnchor else { return }
        UIView.animate(withDuration: 0.2) {
            self.chatMessageActionPanelView.alpha = 0.0
            reactionsViewTopConstraint.constant = self.initialActionPanelTopAnchor
            self.view.layoutIfNeeded()
        }
    }
    
    func flagTapped(for message: MessageViewModel, completion: FlagTapCompletion?) {
        presentFlagActionSheet(for: message, completion: completion)
    }

}

// MARK: - ChatMessageActionPanelDelegate
extension MessageViewController: ChatMessageActionPanelDelegate {
    func chatMessageReactionSelected(for messageViewModel: MessageViewModel, reaction: ReactionID) {
        guard self.canReact else {
            return
        }

        self.canReact = false

        let reactionIsMine = messageViewModel.chatReactions.isMine(forID: reaction)
        chatAdapter?.deselectSelectedMessage()
        chatAdapter?.recordChatReactionSelection(
            for: messageViewModel,
            reaction: reaction,
            isMine: reactionIsMine
        )

        if reactionIsMine, let reactionVoteID = messageViewModel.chatReactions.myVoteID() {
            session?.removeReactions(
                reactionVoteID,
                fromMessageWithID: messageViewModel.id
            ).always {
                self.canReact = true
            }
            messageViewModel.chatReactions.reactions.filter({ $0.isMine }).forEach({
                $0.isMine = false
                $0.myVoteID = nil
                $0.voteCount -= 1
            })
        } else {
            let reactionToRemove = messageViewModel.chatReactions.myVoteID()
            session?.sendReaction(
                messageID: messageViewModel.id,
                reaction,
                reactionToRemove: reactionToRemove
            ).always {
                self.canReact = true
            }
            messageViewModel.chatReactions.reactions.filter({ $0.isMine }).forEach({
                $0.isMine = false
                $0.myVoteID = nil
                $0.voteCount -= 1
            })
            messageViewModel.chatReactions.reactions.first(where: { $0.id == reaction })?.isMine = true
            messageViewModel.chatReactions.reactions.first(where: { $0.id == reaction })?.voteCount += 1
        }
    }
    
    func chatFlagButtonPressed(for messageViewModel: MessageViewModel) {
        presentFlagActionSheet(for: messageViewModel, completion: nil)
        chatAdapter?.deselectSelectedMessage()
        chatAdapter?.recordChatFlagButtonPressed(for: messageViewModel)
    }
}

// MARK: - Private
private extension MessageViewController {
    func presentFlagActionSheet(for message: MessageViewModel, completion: FlagTapCompletion?) {
        let blockTitle = NSLocalizedString("Block this user", comment: "")
        let reportTitle = NSLocalizedString("Report message", comment: "")
        let cancelTitle = NSLocalizedString("Cancel", comment: "")

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: blockTitle, style: .default) { [weak self] _ in
            self?.presentBlockConfirmationAlert(for: message, completion: completion)
        })

        sheet.addAction(UIAlertAction(title: reportTitle, style: .default) { [weak self] _ in
            self?.presentReportConfirmationAlert(for: message, completion: completion)
        })

        sheet.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { [weak self] _ in
            self?.chatAdapter?.recordChatFlagActionSelected(for: message, result: .cancelled)
        })

        present(sheet, animated: true, completion: nil)
    }

    func presentBlockConfirmationAlert(for message: MessageViewModel, completion: FlagTapCompletion?) {
        let title = NSLocalizedString("Block", comment: "")
        let username = message.username
        let alertMessage = "You will no longer see messages from \(username)"
        let dismissTitle = NSLocalizedString("OK", comment: "")

        let alert = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissTitle, style: .default) { [weak self] _ in
            let senderID = message.sender?.id
            let result: ChatActionResult = senderID != nil
                ? .blocked(userID: senderID!, dueTo: message)
                : .cancelled
            self?.chatAdapter?.recordChatFlagActionSelected(for: message, result: result)
        })
        present(alert, animated: true, completion: nil)
    }

    func presentReportConfirmationAlert(for message: MessageViewModel, completion: FlagTapCompletion?) {
        let title = NSLocalizedString("Report", comment: "")
        let alertMessage = NSLocalizedString("This message has been reported to the moderators. Thank You.", comment: "")
        let dismissTitle = NSLocalizedString("OK", comment: "")

        let alert = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissTitle, style: .default) { [weak self] _ in
            self?.chatAdapter?.recordChatFlagActionSelected(for: message, result: .reported(message: message))
        })
        present(alert, animated: true, completion: nil)
    }
}
