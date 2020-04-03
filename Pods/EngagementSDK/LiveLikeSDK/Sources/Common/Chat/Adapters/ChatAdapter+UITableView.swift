//
//  ChatAdapter+UITableView.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 9/13/19.
//

import Foundation
import UIKit

internal extension ChatAdapter {
    func shouldFilterOut(message: MessageViewModel) -> Bool {
        guard let sender = message.sender else {
            return false
        }

        return blockList.contains(user: sender)
    }

    func resetCell(_ cell: UITableViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
    }

    /// Tries to update table with inserts or appends
    func updateTable() {
        if !updatingTable {
            if messagesToInsert.count > 0 {
                prependMessagesToTable()
            } else if messagesToAppend.count > 0 {
                updatingTable = appendMessagesToTable()
            } else if messagesToUpdate.count > 0 {
                updateMessagesInTable()
            }
        }
    }

    /// Inserts messages to the top (0 index) of the table
    func prependMessagesToTable() {
        guard !messagesToInsert.isEmpty else { return }
        guard let tableView = tableView else { return }

        self.updatingTable = true
        let currentRowAfterInsert = messagesToInsert.count
        let isFirstMessagesInTable = messagesDisplayed.isEmpty

        messagesDisplayed.insert(contentsOf: messagesToInsert, at: 0)
        messagesToInsert.removeAll()

        tableView.reloadData()
        tableView.layoutIfNeeded()

        // Scroll the most recent row if these are the first messages in the table
        if isFirstMessagesInTable, tableView.numberOfRows(inSection: 0) > 1 {
            let lastRow = tableView.numberOfRows(inSection: 0) - 1
            tableView.scrollToRow(
                at: IndexPath(row: lastRow, section: 0),
                at: .bottom,
                animated: false
            )
        } else {
            // make sure that currentRowAfterInsert is in range for scroll
            if currentRowAfterInsert < tableView.numberOfRows(inSection: 0) && currentRowAfterInsert >= 0 {
                // scroll back to the position we were in before insertion
                tableView.scrollToRow(
                    at: IndexPath(row: currentRowAfterInsert, section: 0),
                    at: .top,
                    animated: false
                )
            }
        }

        self.updatingTable = false
    }

    /// Appends messages to the bottom of the table view
    func appendMessagesToTable() -> Bool {
        guard !messagesToAppend.isEmpty else { return false }
        guard let tableView = tableView, !isDragging else { return false }

        let messagesToAppendSnapshot = self.messagesToAppend
        self.messagesToAppend.removeAll()

        firstly {
            Promises.all(messagesToAppendSnapshot.map { self.messageViewModelFactory.create(from: $0) })
        }.then(on: DispatchQueue.main) { messages -> Promise<Void> in
            return Promise(queue: DispatchQueue.main) { fulfill, _ in
                var indexPathsForInsert = [IndexPath]()
                let startingRow = self.messagesDisplayed.count
                for index in messagesToAppendSnapshot.indices {
                    indexPathsForInsert.append(IndexPath(row: startingRow + index, section: 0))
                }
                tableView.insertMessagesAnimated(at: indexPathsForInsert, updateData: { [weak self] in
                    guard let self = self else { return }
                    self.messagesDisplayed.append(contentsOf: messages)
                    }, completion: { [weak self] _ in
                        guard let self = self else { return }
                        self.refreshSnapToLiveVisiblity()
                        if self.shouldScrollToNewestMessageOnArrival {
                            self.scrollToMostRecentCompletion = { [weak self] in
                                self?.updatingTable = false
                                self?.voiceOverForAccessibility()
                                fulfill(())
                            }
                            self.scrollToMostRecent(returnMethod: .scroll)
                        } else {
                            self.updatingTable = false
                            fulfill(())
                        }
                })
            }
        }.catch {
            log.error($0)
        }
        return true
    }
    
    /// Determine whether the chat view needs to scroll to the most recent chat message for incoming message
    func shouldScrollToMostRecent() -> Bool {
        guard !isDragging else { return false }
        guard let lastVisibleRow = tableView?.indexPathsForVisibleRows?.last?.row else { return false }
        
        // subtract 1 to account for the new message, otherwise race conditions happen
        let displayedMessageAmount = messagesDisplayed.count > 1 ? messagesDisplayed.count - 1 : messagesDisplayed.count
        return displayedMessageAmount - lastVisibleRow <= snapToLiveAfterMessageAmount
    }
    
    func chatScrollInitiated() {
        viewedMessages += 1
        eventRecorder.record(.chatScrollInitiated)
    }
    
    func chatScrollCompleted() {
        let maxReached = oldestMessageIndex == 0
        let properties = ChatScrollCompletedProperties(messagesScrolledThrough: viewedMessages, maxReached: maxReached, returnMethod: scrollingReturnMethod)
        eventRecorder.record(.chatScrollCompleted(properties: properties))
        oldestMessageIndex = Int.max
        viewedMessages = 0
        scrollingReturnMethod = .scroll
    }
    
    func refreshSnapToLiveVisiblity() {
        guard let lastVisibleRow = tableView?.indexPathsForVisibleRows?.last?.row else { return }
        if lastVisibleRow < messagesDisplayed.count - snapToLiveAfterMessageAmount {
            shouldHideSnapToLive = false
        } else {
            shouldHideSnapToLive = true
        }
    }
    
    /// Read out the latest posted message using Voiceover Acccessibility
    func voiceOverForAccessibility() {
        guard let tableView = tableView else { return }
        guard let lastIndexPath = tableView.indexPathsForVisibleRows?.last else { return }
        let lastCell = tableView.cellForRow(at: lastIndexPath)
        UIAccessibility.post(notification: .layoutChanged, argument: lastCell)
    }
}

// MARK: - UITableViewDataSource
extension ChatAdapter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesDisplayed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView
                .dequeueReusableCell(withIdentifier: chatCellIdentifier)
                as? ProxyTableViewCell
            else {
                assertionFailure("ChatAdapter couldn't find a cell with the reuse identifier 'chatMessageCell'")
                return UITableViewCell()
        }
        
        let messageViewModel = messagesDisplayed[indexPath.row]
        resetCell(cell)
        
        let cellView = chatViewFactory(
            ChatViewHandlerConfig(
                messageViewModel: messageViewModel,
                indexPath: indexPath,
                theme: theme,
                timestampFormatter: self.timestampFormatter,
                shouldDisplayDebugVideoTime: shouldDisplayDebugVideoTime
            )
        )
        cell.contentView.addSubview(cellView)
        cellView.constraintsFill(to: cell.contentView)
        cell.selectableView = cellView
        cell.accessibilityLabel = "\(messageViewModel.username), \(messageViewModel.message)"
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatAdapter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if
            let selectedIndexPath = tableView.indexPathForSelectedRow,
            tableView.cellForRow(at: selectedIndexPath) != nil
        {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
            self.tableView(tableView, didDeselectRowAt: selectedIndexPath)
            return nil
        }

        // Don't allow selection of deleted
        guard
            let messageViewModel = messagesDisplayed[safe: indexPath.row],
            !messageViewModel.isDeleted
        else {
            return nil
        }

        return indexPath

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ProxyTableViewCell else {
            return
        }

        selectSelectedMessage(cell: cell)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ProxyTableViewCell else {
            return
        }
        
        cellDeselected(cell: cell, tableView: tableView)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if case .active = scrollingState {
            if lastMessageIsVisible {
                scrollingState = .inactive
                chatScrollCompleted()
            } else {
                if indexPath.row < oldestMessageIndex {
                    oldestMessageIndex = indexPath.row
                    viewedMessages += 1
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Check if the display ending cell this is the last message.
        if case .tracking = scrollingState, let row = tableView.indexPathsForVisibleRows?.last?.row, row == (indexPath.row - 1) {
            scrollingState = .active
            chatScrollInitiated()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragging = true
        didInteractWithMessageView = true
        if lastMessageIsVisible {
            if let firstIndex = tableView?.indexPathsForVisibleRows?.first {
                oldestMessageIndex = firstIndex.row
            }
            scrollingState = .tracking
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isDragging = decelerate

        self.scrollToMostRecentCompletion?()
        self.scrollToMostRecentCompletion = nil
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDragging = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isDragging else { return }
        
        refreshSnapToLiveVisiblity()
        
        // check if scrolled to top
        if scrollView.contentOffset.y == 0 {
            didScrollToTop?()
        }

        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            //you reached end of the table
            self.shouldScrollToNewestMessageOnArrival = true
        }
        
        if
            let lastVisibleRow = tableView?.indexPathsForVisibleRows?.last?.row,
            lastVisibleRow < messagesDisplayed.count - snapToLiveAfterMessageAmount
        {
            self.shouldScrollToNewestMessageOnArrival = false
        } else {
            self.shouldScrollToNewestMessageOnArrival = true
        }

        deselectSelectedMessage()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.scrollToMostRecentCompletion?()
        self.scrollToMostRecentCompletion = nil
    }

}
