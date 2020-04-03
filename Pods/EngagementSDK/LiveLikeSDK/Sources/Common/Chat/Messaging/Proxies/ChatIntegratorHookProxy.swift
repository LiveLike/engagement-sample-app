//
//  ChatIntegratorHookProxy.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/8/19.
//

import Foundation

/// Pushes messages to the integrator's ChatDelegate
class ChatIntegratorHookProxy: ChatProxy {

    var downStreamProxyInput: ChatProxyInput?
    weak var delegate: ContentSessionDelegate?
    weak var session: ContentSession?

    init(delegate: ContentSessionDelegate?, session: ContentSession?){
        self.delegate = delegate
        self.session = session
    }

    func publish(channel: String, messagesFromHistory messages: [ChatMessageType]) {
        downStreamProxyInput?.publish(channel: channel, messagesFromHistory: messages)
    }

    func publish(channel: String, newestMessages messages: [ChatMessageType]) {
        downStreamProxyInput?.publish(channel: channel, newestMessages: messages)
        if
            let delegate = delegate,
            let session = session
        {
            messages.forEach { message in
                let chatMessage = ChatMessage(
                    senderUsername:
                    message.nickname,
                    message: message.message,
                    timestamp: message.timestamp
                )
                delegate.chat?(session: session, roomID: message.roomID, newMessage: chatMessage)
            }
        }
    }

    func publish(newMessage: ChatMessageType) {
        downStreamProxyInput?.publish(newMessage: newMessage)
        let chatMessage = ChatMessage(
            senderUsername:
            newMessage.nickname,
            message: newMessage.message,
            timestamp: newMessage.timestamp
        )
        
        if let delegate = delegate,
            let session = session {
            delegate.chat?(session: session, roomID: newMessage.roomID, newMessage: chatMessage)
        }
    }

    func publish(messageUpdated message: ChatMessageType) {
        downStreamProxyInput?.publish(messageUpdated: message)
    }

    func deleteMessage(channel: String, messageId: ChatMessageID) {
        downStreamProxyInput?.deleteMessage(channel: channel, messageId: messageId)
    }
}
