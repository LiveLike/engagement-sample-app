//
//  ChatQueue.swift
//  LiveLikeSDK
//

import Foundation

class ChatQueue: ChatProxy {
    private let queue: DispatchQueue

    let userID: ChatUser.ID
    
    weak var downStreamProxyInput: ChatProxyInput?

    init(userID: ChatUser.ID, queue: DispatchQueue = .main) {
        self.userID = userID
        self.queue = queue
    }
}

// MARK: - ChatProxyInput

extension ChatQueue {
    func publish(channel: String, messagesFromHistory messages: [ChatMessageType]) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.publish(channel: channel, messagesFromHistory: messages)
        }
    }

    func publish(channel: String, newestMessages messages: [ChatMessageType]) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.publish(channel: channel, newestMessages: messages)
        }
    }

    func publish(newMessage: ChatMessageType) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.publish(newMessage: newMessage)
        }
    }

    func publish(messageUpdated message: ChatMessageType) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.publish(messageUpdated: message)
        }
    }

    func deleteMessage(channel: String, messageId: ChatMessageID) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.deleteMessage(channel: channel, messageId: messageId)
        }
    }

    func error(_ error: Error) {
        guard let downStream = self.downStreamProxyInput else { return }
        queue.async {
            downStream.error(error)
        }
    }
}
