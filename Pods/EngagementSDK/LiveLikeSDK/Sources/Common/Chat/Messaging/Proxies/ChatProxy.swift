//
//  ChatProxy.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-20.
//

import Foundation

typealias ChatProxy = ChatProxyInput & ChatProxyOutput

protocol ChatProxyInput: AnyObject {
    func publish(channel: String, messagesFromHistory messages: [ChatMessageType])
    func publish(channel: String, newestMessages messages: [ChatMessageType])
    func publish(newMessage: ChatMessageType)
    func publish(messageUpdated message: ChatMessageType)
    func deleteMessage(channel: String, messageId: ChatMessageID)
    func error(_ error: Error)
}

protocol ChatProxyOutput: AnyObject {
    var downStreamProxyInput: ChatProxyInput? { get set }
}

extension ChatProxyOutput {
    func addProxy(_ proxy: () -> ChatProxy) -> ChatProxy {
        let input = proxy()
        downStreamProxyInput = input
        return input
    }

    @discardableResult
    func addProxy(_ proxy: () -> ChatQueue) -> ChatQueue {
        let input = proxy()
        downStreamProxyInput = input
        return input
    }
}

extension ChatProxyInput where Self: ChatProxyOutput {
    func error(_ error: Error) {
        downStreamProxyInput?.error(error)
    }
}

extension ChatProxyInput {
    func error(_ error: Error) {
        print("Received error: \(error)")
    }
}
