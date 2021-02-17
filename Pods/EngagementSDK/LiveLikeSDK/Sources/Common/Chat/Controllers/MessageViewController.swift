//
//  MessagesViewController.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-08.
//

import UIKit

final public class MessageViewController: UIViewController {

    private var chatAdapter: ChatAdapter? {
        didSet {
            tableView.dataSource = chatAdapter
            chatAdapter?.tableView = tableView
            chatAdapter?.actionsDelegate = self
            chatAdapter?.hideSnapToLive = { [weak self] hide in
                self?.snapToLiveIsHidden(hide)
            }
            chatAdapter?.didScrollToTop = { [weak self] in
                self?.loadMoreHistory()
            }
            chatAdapter?.timestampFormatter = self.messageTimestampFormatter
            chatAdapter?.shouldDisplayDebugVideoTime = self.shouldDisplayDebugVideoTime
            self.dismissChatMessageActionPanel()
            chatAdapter?.setTheme(theme)
        }
    }

    // MARK: - Internal Properties

    private let customTableViewController: CustomTableViewController = {
        let vc = CustomTableViewController()
        vc.tableView.translatesAutoresizingMaskIntoConstraints = false
        vc.tableView.backgroundColor = UIColor.clear
        vc.tableView.separatorStyle = .none
        vc.tableView.showsVerticalScrollIndicator = false
        return vc
    }()

    var tableView: UITableView {
        return customTableViewController.tableView
    }

    var tableTrailingConstraint: NSLayoutConstraint?
    var tableLeadingConstraint: NSLayoutConstraint?
    var chatMessageActionPanelViewTopAnchor: NSLayoutConstraint?
    var reactionPopUpHorizontalAlignment: NSLayoutConstraint?
    var shouldShowIncomingMessages: Bool = true {
        didSet {
            chatAdapter?.shouldShowIncomingMessages = shouldShowIncomingMessages
        }
    }

    public var messageTimestampFormatter: TimestampFormatter? = { date in
        let dateFormatter = DateFormatter()
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d hh:mm")
        return dateFormatter.string(from: date)
    }

    /// Determines whether the user is able to post images into chat
    public var shouldDisplayDebugVideoTime: Bool = false

    /// A flag that determines whether we should scroll to display the newest message when it is received
    var shouldScrollToNewestMessageOnArrival: Bool {
        get {
            guard let chatAdapter = chatAdapter else { return true }
            return chatAdapter.shouldScrollToNewestMessageOnArrival
        }
        set {
            chatAdapter?.shouldScrollToNewestMessageOnArrival = newValue
        }
    }

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
        view.accessibilityLabel = "EngagementSDK.chat.reactions.accessibility.reactionPanelOpened".localized()
        view.accessibilityTraits = .allowsDirectInteraction
        return view
    }()
    
    private var initialActionPanelTopAnchor: CGFloat = 0.0
    private var theme: Theme = Theme()
    
    private var emptyChatCustomView: UIView?

    private var stickerPacks: [StickerPack] = []

    weak var chatSession: InternalChatSessionProtocol? {
        didSet {
            guard let chatSession = chatSession else { return }
            firstly {
                chatSession.reactionsVendor.getReactions()
            }.then { [weak self] reactionsViewModel in
                self?.chatMessageActionPanelView.setUp(
                    reactions: .init(reactionAssets: reactionsViewModel),
                    chatSession: chatSession
                )
            }.catch {
                log.error($0.localizedDescription)
            }
        }
    }

    /// Removes the current chat session if there is one set.
    public func clearChatSession() {
        self.chatSession?.removeInternalDelegate(self)
        self.chatSession = nil
        self.chatAdapter = nil
        self.stickerPacks = []
    }

    public func setChatSession(_ chatSession: ChatSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.clearChatSession()

            guard let chatSession = chatSession as? InternalChatSessionProtocol else { return }
            self.chatSession = chatSession

            chatSession.stickerRepository.getStickerPacks { [weak self] result in
                guard let self = self else { return}

                DispatchQueue.main.async {
                    switch result {
                    case .success(let stickerPacks):
                        self.stickerPacks = stickerPacks
                    case .failure(let error):
                        log.error("Failed to get sticker packs with error: \(error)")
                    }

                    let factory = MessageViewModelFactory(
                        stickerPacks: self.stickerPacks,
                        channel: "",
                        reactionsFactory: chatSession.reactionsVendor,
                        mediaRepository: EngagementSDK.mediaRepository,
                        theme: self.theme
                    )

                    let adapter = ChatAdapter(
                        messageViewModelFactory: factory,
                        eventRecorder: chatSession.eventRecorder,
                        blockList: chatSession.blockList,
                        chatSession: chatSession,
                        shouldShowIncomingMessages: self.shouldShowIncomingMessages
                    )

                    chatSession.addInternalDelegate(self)
                    self.chatAdapter = adapter
                    self.chatSession(chatSession, didRecieveMessageHistory: chatSession.messages)
                }
            }
        }
    }

    public func setContentSession(_ contentSession: ContentSession) {
        guard let contentSession = contentSession as? InternalContentSession else { return }

        contentSession.getChatSession { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatSession):
                self.setChatSession(chatSession)
            case .failure(let error):
                log.error(error)
            }
        }

        /// Normally this would be done in the session `didSet` observer
        /// however when a property is weak the observer does not get notified
        /// when it's set to nil.
        /// See dicussion at https://stackoverflow.com/a/24317758/1615621
        contentSession.sessionDidEnd = { [weak self] in
            self?.chatAdapter = nil
        }
    }

    /// Used to prevent the user from spamming reactions before receiving and update from the server
    private var canReact: Bool = true

    private var snapToLiveButton = SnapToLiveButton()
    private var snapToLiveBottomConstraint: NSLayoutConstraint?
    private var snapToLiveHorizontalAligntmentConstraint: NSLayoutConstraint?
    private let snapToLiveDefaultHorizontalMargin: CGFloat = 20

    // MARK: - Initializers

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        setupActivityIndicator()
        setupTableView()
        setupSnapToLiveButton()
        chatMessageActionPanelView.chatMessageActionPanelDelegate = self
        setTheme(theme)
    }

    public override func viewDidAppear(_ animated: Bool) {
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

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // swiftlint:disable notification_center_detachment
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

    private func setupSnapToLiveButton() {
        snapToLiveButton.translatesAutoresizingMaskIntoConstraints = false
        snapToLiveButton.alpha = 0.0
        view.addSubview(snapToLiveButton)
        
        snapToLiveButton.addGestureRecognizer({
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(snapToLive))
            tapGestureRecognizer.numberOfTapsRequired = 1
            return tapGestureRecognizer
        }())
        
        snapToLiveButton.livelike_shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        snapToLiveButton.livelike_shadowOpacity = 0.3
        snapToLiveButton.livelike_shadowRadius = 3
        snapToLiveButton.livelike_shadowOffset = CGSize(width: 0, height: 0)
        
        snapToLiveIsHidden(true)
    }

    @objc func snapToLive() {
        shouldScrollToNewestMessageOnArrival = true
        scrollToMostRecent(force: true, returnMethod: .snapToLive)
    }

    private func snapToLiveIsHidden(_ isHidden: Bool) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.snapToLiveBottomConstraint?.constant = isHidden ? self.snapToLiveButton.bounds.height : self.theme.snapToLiveButtonVerticalOffset
            self.view.layoutIfNeeded()
            self.snapToLiveButton.alpha = isHidden ? 0 : 1
        }, completion: nil)
    }

    private func setupTableView() {
        addChild(customTableViewController)
        view.addSubview(customTableViewController.view)
        view.addSubview(chatMessageActionPanelView)

        tableLeadingConstraint = tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.chatLeadingMargin)
        tableTrailingConstraint = view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: theme.chatTrailingMargin)
        reactionPopUpHorizontalAlignment = chatMessageActionPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.reactionsPopupHorizontalOffset)
        chatMessageActionPanelViewTopAnchor = chatMessageActionPanelView.topAnchor.constraint(equalTo: view.topAnchor)
        let constraints = [
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableLeadingConstraint!,
            tableTrailingConstraint!,
            
            chatMessageActionPanelView.widthAnchor.constraint(greaterThanOrEqualToConstant: 46.0),
            chatMessageActionPanelView.heightAnchor.constraint(equalToConstant: 36.0),
            chatMessageActionPanelViewTopAnchor!,
            reactionPopUpHorizontalAlignment!
        ]
        
        NSLayoutConstraint.activate(constraints)

        tableView.dataSource = chatAdapter
    }

    func loadMoreHistory(){
        guard let chatSession = chatSession else { return }
        isLoading(true)

        firstly {
            chatSession.loadPreviousMessagesFromHistory()
        }.always {
            self.isLoading(false)
        }.catch { error in
            log.error("Failed to load history: \(error.localizedDescription)")
        }
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
        activityIndicator.color = theme.chatLoadingIndicatorColor
        self.view.backgroundColor = theme.chatBodyColor

        self.emptyChatCustomView?.removeFromSuperview()
        if let newEmptyChatCustomView = theme.emptyChatCustomView {
            newEmptyChatCustomView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(newEmptyChatCustomView, at: 0)
            newEmptyChatCustomView.constraintsFill(to: view)
            // use the hidden state of previous emptyChatCustomView
            newEmptyChatCustomView.isHidden = self.emptyChatCustomView?.isHidden ?? true
        }
        self.emptyChatCustomView = theme.emptyChatCustomView
        
        // Snap To Live position setup
        self.snapToLiveButton.setTheme(theme)
        snapToLiveHorizontalAligntmentConstraint?.isActive = false
        snapToLiveBottomConstraint?.isActive = false
        
        switch theme.snapToLiveButtonHorizontalAlignment {
        case .left:
            snapToLiveHorizontalAligntmentConstraint = snapToLiveButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: snapToLiveDefaultHorizontalMargin + theme.snapToLiveButtonHorizontalOffset
            )
        case .center:
            snapToLiveHorizontalAligntmentConstraint = snapToLiveButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor,
                constant: theme.snapToLiveButtonHorizontalOffset
            )
        case .right:
            snapToLiveHorizontalAligntmentConstraint = snapToLiveButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -snapToLiveDefaultHorizontalMargin - theme.snapToLiveButtonHorizontalOffset
            )
        }
        snapToLiveHorizontalAligntmentConstraint?.isActive = true
        snapToLiveBottomConstraint = snapToLiveButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: theme.snapToLiveButtonVerticalOffset
        )
        snapToLiveBottomConstraint?.isActive = true
        
        reactionPopUpHorizontalAlignment?.isActive = false
        switch theme.reactionsPopupHorizontalAlignment {
        case .left:
            reactionPopUpHorizontalAlignment = chatMessageActionPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.reactionsPopupHorizontalOffset)
        case .center:
            reactionPopUpHorizontalAlignment = chatMessageActionPanelView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: theme.reactionsPopupHorizontalOffset)
        case .right:
            reactionPopUpHorizontalAlignment = chatMessageActionPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: theme.reactionsPopupHorizontalOffset)
        }
        reactionPopUpHorizontalAlignment?.isActive = true
    }
    
    private func updateNoMessagesCustomView(messageCount: Int){
        self.emptyChatCustomView?.isHidden = messageCount > 0
    }

    func orientationWillChange() {
        self.chatAdapter?.orientationWillChange()
    }

    func orientationDidChange() {
        self.chatAdapter?.orientationDidChange()
    }

    func scrollToMostRecent(force: Bool = false, returnMethod: ChatScrollingReturnMethod) {
        chatAdapter?.scrollToMostRecent(force: force, returnMethod: returnMethod)
    }

}

// MARK: - ChatActionsDelegate

extension MessageViewController: ChatActionsDelegate {
    var actionPanelHeight: CGFloat {
        return chatMessageActionPanelView.bounds.height + theme.reactionsPopupVerticalOffset + 20
    }

    func chatAdapter(_ chatAdapter: ChatAdapter, messageCountDidChange count: Int) {
        self.isLoading(false)
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
            
            var topAnchorConstant: CGFloat = 0.0
            switch self.theme.reactionsPopupVerticalAlignment {
            case .top:
                topAnchorConstant = cellRect.origin.y - 44.0 - self.theme.reactionsPopupVerticalOffset
            case .center:
                topAnchorConstant = (cellRect.origin.y + cellRect.height/2 + self.theme.reactionsPopupVerticalOffset) - 22
            case .bottom:
                topAnchorConstant = cellRect.origin.y + cellRect.height + self.theme.reactionsPopupVerticalOffset - 36
            }
            
            actionPanelTopAnchor.constant = direction == .up ? topAnchorConstant : cellRect.origin.y + cellRect.size.height + self.theme.reactionsPopupVerticalOffset
            
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

        if reactionIsMine, let reactionVoteID = messageViewModel.chatReactions.myVoteID() {
            chatAdapter?.recordChatReactionRemoved(for: messageViewModel, reactionId: reaction)
            chatSession?.removeMessageReactions(
                reaction: reactionVoteID,
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
            chatAdapter?.recordChatReactionAdded(for: messageViewModel, reactionId: reaction)
            let reactionToRemove = messageViewModel.chatReactions.myVoteID()
            chatSession?.sendMessageReaction(
                messageViewModel.id,
                reaction: reaction,
                reactionsToRemove: reactionToRemove
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
        let blockTitle = "EngagementSDK.chat.flagMsgMenu.blockUser".localized()
        let reportTitle = "EngagementSDK.chat.flagMsgMenu.reportMessage".localized()
        let cancelTitle = "EngagementSDK.chat.flagMsgMenu.cancel".localized()
        
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: alertStyle)
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
        let title = "EngagementSDK.chat.blockConfirmationAlert.title".localized()
        let username = message.username
        let alertMessage = "EngagementSDK.chat.blockConfirmationAlert.message".localized(withParam: username)
        let dismissTitle = "EngagementSDK.chat.blockConfirmationAlert.confirm".localized()

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
        let title = "EngagementSDK.chat.reportMsgConfirmationAlert.title".localized()
        let alertMessage = "EngagementSDK.chat.reportMsgConfirmationAlert.message".localized()
        let dismissTitle = "EngagementSDK.chat.reportMsgConfirmationAlert.confirm".localized()

        let alert = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissTitle, style: .default) { [weak self] _ in
            self?.chatAdapter?.recordChatFlagActionSelected(for: message, result: .reported(message: message))
        })
        present(alert, animated: true, completion: nil)
    }
}

extension MessageViewController: InternalChatSessionDelegate {
    func chatSession(_ chatSession: ChatSession, didRecieveError error: Error) { }

    public func chatSession(_ chatSession: ChatSession, didRecieveNewMessage message: ChatMessage) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(newMessage: message)
        }
    }

    func chatSession(_ chatSession: ChatSession, didRecieveMessageHistory messages: [ChatMessage]) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(messagesFromHistory: messages)
        }
    }

    func chatSession(_ chatSession: ChatSession, didRecieveMessageUpdate message: ChatMessage) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(messageUpdated: message)
        }
    }

    func chatSession(_ chatSession: ChatSession, didRecieveMessageDeleted messageID: ChatMessageID) {
        DispatchQueue.main.async {
            self.chatAdapter?.deleteMessage(messageId: messageID)
        }
    }
}

private class CustomTableViewController: UIViewController {

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        NSLayoutConstraint.activate(tableView.fillConstraints(to: view))

        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last {
            tableView.scrollToRow(at: lastVisibleIndexPath, at: .bottom, animated: false)
        }
    }

}
