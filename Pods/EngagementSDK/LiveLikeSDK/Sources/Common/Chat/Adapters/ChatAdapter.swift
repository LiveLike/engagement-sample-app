//
//  ChatAdapter.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-19.
//

import UIKit

final class ChatAdapter: NSObject {
    let chatCellIdentifier = "chatMessageCellID"

    weak var actionsDelegate: ChatActionsDelegate?

    weak var tableView: UITableView? {
        didSet {
            guard let tableView = tableView else { return }

            tableView.delegate = self
            let cellNib = UINib(nibName: "ChatMessageTableViewCell", bundle: Bundle(for: ChatMessageTableViewCell.self))
            tableView.register(cellNib, forCellReuseIdentifier: chatCellIdentifier)
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.reloadData()
        }
    }

    var hideSnapToLive: ((Bool) -> Void)?
    var didScrollToTop: (() -> Void)?
    var timestampFormatter: TimestampFormatter?
    var shouldDisplayDebugVideoTime: Bool = false
    var shouldShowIncomingMessages: Bool

    // Private
    internal var shouldHideSnapToLive = true {
        didSet {
            if shouldHideSnapToLive != oldValue {
                hideSnapToLive?(shouldHideSnapToLive)
            }
        }
    }
    
    internal let messageReporter: MessageReporter?
    internal let eventRecorder: EventRecorder
    internal var theme: Theme = Theme()
    internal var messagesDisplayed = [MessageViewModel]() {
        didSet {
            self.actionsDelegate?.chatAdapter(
                self,
                messageCountDidChange: messagesDisplayed.count
            )
        }
    }

    /// The messages waiting to be appended to the bottom of the table (new messages)
    internal var messagesToAppend = [ChatMessage]()
    /// The messages waiting to be inserted to the top of the table (older messages from history)
    var messagesToInsert = [MessageViewModel]()
    var messagesToUpdate = [MessageViewModel]()
    internal var blockList: BlockList
    internal var updatingTable = false
    internal let messageViewModelFactory: MessageViewModelFactory
    internal var isDragging = false {
        didSet {
            if isDragging == false, scrollingState == .tracking {
                scrollingState = .inactive
            }
        }
    }
    
    internal var lastMessageIsVisible: Bool {
        if let lastVisibleRow = tableView?.indexPathsForVisibleRows?.last?.row, lastVisibleRow == messagesDisplayed.count - 1 {
            return true
        }
        return false
    }

    internal var lastRowWasVisible = false
    // Analytics

    internal var oldestMessageIndex: Int = Int.max
    internal var viewedMessages: Int = 0
    internal var scrollingState: ScrollingState = .inactive
    internal var scrollingReturnMethod: ChatScrollingReturnMethod = .scroll
    
    // keeps last bottom visible row before orientation change in case we need to scroll to it
    private var lastBottomVisibleRow: Int?
    private var isReactionsPanelOpen: Bool = false
    
    /// The amount of newest messages a user needs to scroll past
    /// in order for Snap To Live button to appear
    internal let snapToLiveAfterMessageAmount: Int = 3

    var scrollToMostRecentCompletion: (() -> Void)?

    /// A flag that determines whether we should scroll to display the newest message when it is received
    var shouldScrollToNewestMessageOnArrival: Bool = true

    var updateTimer: DispatchSourceTimer?
    
    var chatSession: InternalChatSessionProtocol
    
    init(
        messageViewModelFactory: MessageViewModelFactory,
        eventRecorder: EventRecorder,
        blockList: BlockList,
        chatSession: InternalChatSessionProtocol,
        shouldShowIncomingMessages: Bool
    ) {
        self.messageReporter = nil
        self.messageViewModelFactory = messageViewModelFactory
        self.eventRecorder = eventRecorder
        self.blockList = blockList
        self.chatSession = chatSession
        self.shouldShowIncomingMessages = shouldShowIncomingMessages
        super.init()

        updateTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        updateTimer?.schedule(deadline: .now(), repeating: .milliseconds(200))
        updateTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.shouldShowIncomingMessages == true {
                self.updateTable()
            }
        }
        updateTimer?.resume()
    }

    deinit {
        updateTimer?.cancel()
        updateTimer = nil
    }
}

extension ChatAdapter {
    func setTheme(_ theme: Theme) {
        self.theme = theme
    }

    /// Attempts to scroll to the most recent message
    ///
    /// - Parameters:
    ///   - force: When set to `true`, will always scroll to last item including during a dragging session
    ///   - returnMethod: Describes the method that initiated the call (scroll, snapToLive or keyboard)
    func scrollToMostRecent(force: Bool = false, returnMethod: ChatScrollingReturnMethod) {
        scrollingReturnMethod = returnMethod
        if isDragging, !force { return }
        guard let tableView = tableView else { return }
        guard tableView.contentSize.height > tableView.bounds.height else {
            self.updatingTable = false
            return
        }
        if messagesDisplayed.count > 1 {
            tableView.scrollToRow(at: IndexPath(row: messagesDisplayed.count - 1, section: 0), at: .bottom, animated: true)
            shouldHideSnapToLive = true
        }

        deselectSelectedMessage()
    }

    func orientationWillChange() {
        // Check if the last row is displayed prior to rotation
        lastRowWasVisible = lastMessageIsVisible
        lastBottomVisibleRow = tableView?.indexPathsForVisibleRows?.last?.row
        deselectSelectedMessage()
    }

    func orientationDidChange() {
        // If the last row was visible as the orientation change started, scroll to the said last
        // row when the orientation change has completed
        if lastRowWasVisible {
            scrollToMostRecent(force: true, returnMethod: .scroll)
        } else {
            if let lastBottomVisibleRow = lastBottomVisibleRow {
                tableView?.scrollToRow(at: IndexPath(row: lastBottomVisibleRow, section: 0),
                                       at: .bottom,
                                       animated: false)
            }
        }
        lastRowWasVisible = false
    }

    func getMessage(withID id: ChatMessageID) -> MessageViewModel? {
        return messagesDisplayed.first(where: { $0.id == id })
    }
}

// MARK: - ChatProxyInput

extension ChatAdapter {
    func publish(
        messagesFromHistory messages: [ChatMessage]
    ) {
        firstly {
            Promises.all(messages.map({ messageViewModelFactory.create(from: $0)}))
        }.then { messageViewModels in
            let newMessages = messageViewModels.filter({ messageViewModel -> Bool in
                return
                    self.messagesDisplayed.contains(messageViewModel) == false &&
                    self.messagesToInsert.contains(messageViewModel) == false &&
                    self.shouldFilterOut(message: messageViewModel) == false
            })

            self.messagesToInsert.insert(contentsOf: newMessages, at: 0)
            if self.messagesToInsert.isEmpty && self.messagesDisplayed.isEmpty {
                self.actionsDelegate?.chatAdapter(self, messageCountDidChange: 0)
            }
        }.catch {
            log.error($0.localizedDescription)
        }
    }
    
    func publish(
        newestMessages messages: [ChatMessage]
    ) {
        let newMessages = messages.filter({ messageViewModel -> Bool in
            self.messagesDisplayed.contains(where: { $0.id == messageViewModel.messageID }) == false &&
            self.messagesToAppend.contains(messageViewModel) == false &&
            self.blockList.contains(user: messageViewModel.sender) == false
        })
        self.messagesToAppend.append(contentsOf: newMessages)

        firstly {
            Promises.all(messages.map({ messageViewModelFactory.create(from: $0)}))
        }.then { messageViewModels in
            // If message already exists in messagesDisplayed then just update the reactions
            messageViewModels.filter{ self.messagesDisplayed.contains($0) }.forEach { messageViewModel in
                self.messagesToUpdate.append(messageViewModel)
            }
        }.catch {
            log.error($0.localizedDescription)
        }
    }
    
    func publish(newMessage message: ChatMessage) {
        guard
            self.messagesDisplayed.contains(where: { $0.id == message.messageID }) == false,
            self.messagesToAppend.contains(message) == false,
            self.blockList.contains(user: message.sender) == false
        else {
            return
        }

        self.messagesToAppend.append(message)
    }

    func publish(messageUpdated message: ChatMessage) {
        firstly {
            messageViewModelFactory.create(from: message)
        }.then { messageViewModel in
            self.messagesToUpdate.append(messageViewModel)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func updateMessagesInTable(){
        self.updatingTable = true
        var updatedMessageIDs: Set<ChatMessageID> = Set()
        self.messagesToUpdate.forEach { messageToUpdate in
            if self.messagesDisplayed.contains(where: {$0.id == messageToUpdate.id }) {
                self.updateMessage(messageViewModel: messageToUpdate)
                updatedMessageIDs.insert(messageToUpdate.id)
            }
        }
        self.messagesToUpdate.removeAll(where: { updatedMessageIDs.contains($0.id) })
        self.updatingTable = false
    }

    private func updateMessage(messageViewModel: MessageViewModel) {
        guard let indexToUpdate = self.messagesDisplayed.firstIndex(where: { $0.id == messageViewModel.id }) else {
            log.error("Failed to find message to update in messagesDisplayed.")
            return
        }
        self.messagesDisplayed[indexToUpdate] = messageViewModel
        if (self.tableView?.indexPathsForVisibleRows?.first(where: { $0.row == indexToUpdate })) != nil {
            if let cell = self.tableView?.cellForRow(at: IndexPath(row: indexToUpdate, section: 0)) as? ChatMessageTableViewCell {

                if let chatMessageView = cell.contentView.subviews.first(where: { $0 is ChatMessageView}) as? ChatMessageView {
                    chatMessageView.reactionsDisplayView.update(chatReactions: messageViewModel.chatReactions)
                    chatMessageView.reactionHintImageView.isHidden = messageViewModel.chatReactions.totalReactionsCount != 0
                }
            }
        }
        self.actionsDelegate?.actionPanelPrepareToBeShown(messageViewModel: messageViewModel)
    }

    func deleteMessage(messageId: ChatMessageID) {
        guard
            let indexOfDeletedMessage = self.messagesDisplayed.firstIndex(where: { $0.id == messageId })
        else {
            log.error("Chat Message Id: \(messageId) cannot be deleted")
            return
        }
        
        // Dismiss reactions panel if it was open
        if let actionsDelegate = self.actionsDelegate {
            actionsDelegate.dismissChatMessageActionPanel()
        }
        
        // mark messageViewModel as deleted
        self.messagesDisplayed[indexOfDeletedMessage].redact(theme: self.theme)
        
        // only reload the tableView if the deleted cell is currently visbile in the tableView
        updateTableViewIfCellVisible(indexOfCell: indexOfDeletedMessage)
    }

    private func updateTableViewIfCellVisible(indexOfCell index: Int){
        if (self.tableView?.indexPathsForVisibleRows?.first(where: { $0.row == index })) != nil {
            self.tableView?.beginUpdates()
            self.tableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .middle)
            self.tableView?.endUpdates()
        }
    }
}

// MARK: - Private

internal extension ChatAdapter {
    func selectSelectedMessage(cell: ChatMessageTableViewCell) {
        guard let tableView = self.tableView else { return }
        guard let actionsDelegate = self.actionsDelegate else { return }

        if let indexPath = tableView.indexPath(for: cell) {
            let rect = tableView.rectForRow(at: indexPath)
            let rectInScreen = tableView.convert(rect, to: tableView.superview)
            cell.selectableView.isSelected = true
            
            var animationDirection: ChatMessageActionPanelAnimationDirection = .up
            if tableView.bounds.minY > rect.minY - actionsDelegate.actionPanelHeight {
                animationDirection = .down
            }
            
            isReactionsPanelOpen = true
            self.shouldScrollToNewestMessageOnArrival = false
            actionsDelegate.showChatMessageActionPanel(for: messagesDisplayed[indexPath.row],
                                                        cellRect: rectInScreen,
                                                        direction: animationDirection)
        }
    }
    
    func deselectSelectedMessage() {
        if
            let tableView = tableView,
            let indexPath = tableView.indexPathForSelectedRow
        {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let cell = tableView.cellForRow(at: indexPath) as? ChatMessageTableViewCell else {
                return
            }
            
            cellDeselected(cell: cell, tableView: tableView)
        }
    }
    
    /// Used to toggle UI elements/flags on message deselection which happens from multiple places
    func cellDeselected(cell: ChatMessageTableViewCell, tableView: UITableView) {
        cell.selectableView.isSelected = false
        isReactionsPanelOpen = false
        
        // Re-enable autoscroll if we are still at bottom of table when closing reaction panel
        if self.lastMessageIsVisible {
            self.shouldScrollToNewestMessageOnArrival = true
        }
        actionsDelegate?.dismissChatMessageActionPanel()
    }
}

/// The `ScrollingState` is used to help trigger the proper analytic events while a user scrolls.
///
/// - inactive: Is the default state, the last message is visible and the user is not actively dragging
/// - tracking: Is the state while the user starts dragging, but the last message is still in the view
/// - active: Is when the last message is no longer visible
enum ScrollingState {
    case inactive
    case tracking
    case active
}

typealias SelectableView = UIView & Selectable
protocol Selectable {
    var isSelected: Bool { get set }
}

enum ChatActionResult {
    case cancelled
    case blocked(userID: ChatUser.ID, dueTo: MessageViewModel)
    case reported(message: MessageViewModel)
}

typealias FlagTapCompletion = (ChatActionResult) -> Void

protocol ChatActionsDelegate: AnyObject {
    func flagTapped(for message: MessageViewModel, completion: FlagTapCompletion?)
    func showChatMessageActionPanel(for messageViewModel: MessageViewModel, cellRect: CGRect, direction: ChatMessageActionPanelAnimationDirection)
    func dismissChatMessageActionPanel()
    func chatAdapter(_ chatAdapter: ChatAdapter, messageCountDidChange count: Int)
    func actionPanelPrepareToBeShown(messageViewModel: MessageViewModel)
    var actionPanelHeight: CGFloat { get }
}

extension ChatActionsDelegate {
    func flagTapped(for message: MessageViewModel) {
        flagTapped(for: message, completion: nil)
    }
}

protocol ChatActionsDelegateContainer {
    var actionsDelegate: ChatActionsDelegate? { get set }
}
