//
//  SynchronizedChatProxy.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-21.
//

import Foundation

class SynchronizedChatProxy: ChatProxy {
    var downStreamProxyInput: ChatProxyInput?

    private let queue = Queue<ChatMessageType>()
    private var playerTimeSource: PlayerTimeSource?
    private var timer: DispatchSourceTimer?

    private var syncedMessageCache: Set<ChatMessageType> = Set()

    init(playerTimeSource: PlayerTimeSource?) {
        self.playerTimeSource = playerTimeSource
        timer = processQueueForEligibleScheduledEvent()
    }

    deinit {
        self.timer?.cancel()
    }

    func publish(channel: String, messagesFromHistory messages: [ChatMessageType]) {
        // If there is no sync time source then publish immediately
        guard let playerTimeSourceNow = self.playerTimeSource?() else {
            messages.forEach { self.syncedMessageCache.insert($0) }
            downStreamProxyInput?.publish(channel: channel, messagesFromHistory: messages)
            return
        }

        let splitMessages = self.split(messages: messages, byTimestamp: playerTimeSourceNow)
        splitMessages.messagesBeforeTimestamp.forEach { self.syncedMessageCache.insert($0) }

        // Publish messages that were earlier than sync timestamp
        // If there are none then go to the cache
        if splitMessages.messagesBeforeTimestamp.count > 0 {
            downStreamProxyInput?.publish(channel: channel, messagesFromHistory: splitMessages.messagesBeforeTimestamp)
        } else {
            let messagesFromCache = self.syncedMessageCache.sorted(by: { $0.timestamp < $1.timestamp }).suffix(messages.count)
            downStreamProxyInput?.publish(channel: channel, messagesFromHistory: Array(messagesFromCache))
        }

        // Queue messages that are later than sync timestamp
        splitMessages.messagesAfterTimestamp.forEach { m in
            queue.enqueue(element: m)
        }
    }

    func publish(channel: String, newestMessages messages: [ChatMessageType]) {
        // If there is no sync time source then publish immediately
        guard let playerTimeSourceNow = self.playerTimeSource?() else {
            messages.forEach { self.syncedMessageCache.insert($0) }
            downStreamProxyInput?.publish(channel: channel, newestMessages: messages)
            return
        }

        let splitMessages = self.split(messages: messages, byTimestamp: playerTimeSourceNow)
        splitMessages.messagesBeforeTimestamp.forEach { self.syncedMessageCache.insert($0) }

        // Publish messages that were earlier than sync timestamp
        downStreamProxyInput?.publish(
            channel: channel,
            newestMessages: splitMessages.messagesBeforeTimestamp
        )

        // Queue messages that are later than sync timestamp
        splitMessages.messagesAfterTimestamp.forEach { m in
            queue.enqueue(element: m)
        }
    }

    func publish(newMessage: ChatMessageType) {
        // check if message is currently in queue
        if queue.contains(where: { $0 == newMessage }) {
            return
        }

        // if message is mine then publish immediately
        if newMessage.sender.isLocalUser {
            self.syncedMessageCache.insert(newMessage)
            downStreamProxyInput?.publish(newMessage: newMessage)
            return
        }

        // Send message immediately if message is unscheduled or no timesource.
        if newMessage.videoTimestamp == nil || playerTimeSource?() == nil {
            self.syncedMessageCache.insert(newMessage)
            downStreamProxyInput?.publish(newMessage: newMessage)
            return
        }

        // Send message when timeSource has passed timeStamp
        if let timeStamp = newMessage.videoTimestamp, let timeSource = self.playerTimeSource?(), timeStamp <= timeSource {
            self.syncedMessageCache.insert(newMessage)
            downStreamProxyInput?.publish(newMessage: newMessage)
            return
        }
        queue.enqueue(element: newMessage)
    }

    func publish(messageUpdated message: ChatMessageType) {
        downStreamProxyInput?.publish(messageUpdated: message)
    }

    func deleteMessage(channel: String, messageId: ChatMessageID) {
        downStreamProxyInput?.deleteMessage(channel: channel, messageId: messageId)
    }
}

private extension SynchronizedChatProxy {
    // Helper method to split an array of messages into two arrays by timestamp
    // messageBeforeTimestamp are the messages with timestamps before the given timestamp
    // messagesAfterTimestamp are the messages with timestamps after the given timestamp
    func split(
        messages: [ChatMessageType],
        byTimestamp timestamp: TimeInterval
    ) -> (messagesBeforeTimestamp: [ChatMessageType], messagesAfterTimestamp: [ChatMessageType]) {
        // The messages that are earlier than the sync timestamp. These will be shown immediately.
        var beforeTimestamp = [ChatMessageType]()

        // The messages that are later than the sync timestamp. These will be queued for sync.
        var afterTimestamp = [ChatMessageType]()

        messages.forEach { message in
            // If the message doesn't have a timestamp then consider it earlier than sync timestamp
            guard let messageTimestamp = message.videoTimestamp else {
                beforeTimestamp.append(message)
                return
            }

            if messageTimestamp >= timestamp {
                afterTimestamp.append(message)
            } else {
                beforeTimestamp.append(message)
            }
        }

        return (beforeTimestamp, afterTimestamp)
    }

    func processQueueForEligibleScheduledEvent() -> DispatchSourceTimer {
        self.timer?.cancel()
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let nextMessage = self.queue.peek() else { return }

            // If we lose timesource then publish immediately
            if self.playerTimeSource == nil {
                self.syncedMessageCache.insert(nextMessage)
                self.downStreamProxyInput?.publish(newMessage: nextMessage)
                self.queue.removeNext()
                return
            }

            // Send message when timeSource has passed timeStamp
            if let timeStamp = nextMessage.videoTimestamp, let timeSource = self.playerTimeSource?(), timeStamp <= timeSource {
                self.syncedMessageCache.insert(nextMessage)
                self.downStreamProxyInput?.publish(newMessage: nextMessage)
                self.queue.removeNext()
                return
            }
        }
        timer.resume()
        return timer
    }
}
