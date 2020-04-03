//
//  ChatLoggerProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/6/19.
//

import Foundation

class ChatLoggerProxy: ChatProxy {
    var downStreamProxyInput: ChatProxyInput?

    private var playerTimeSource: PlayerTimeSource?

    init(playerTimeSource: PlayerTimeSource?) {
        self.playerTimeSource = playerTimeSource
    }

    func publish(channel: String, messagesFromHistory message: [ChatMessageType]) {
        downStreamProxyInput?.publish(channel: channel, messagesFromHistory: message)
    }

    func publish(channel: String, newestMessages messages: [ChatMessageType]) {
        downStreamProxyInput?.publish(channel: channel, newestMessages: messages)
    }
    
    func publish(newMessage: ChatMessageType) {
        var log: String = "Chat"

        if let minimumScheduledTime = newMessage.videoTimestamp, let playerTimeSource = playerTimeSource?() {
            let videoTimeString = DateFormatter.currentTimeZoneTime.string(from: Date(timeIntervalSince1970: playerTimeSource))
            let chatTimeString = DateFormatter.currentTimeZoneTime.string(from: Date(timeIntervalSince1970: minimumScheduledTime))
            log.append(" [chat \(chatTimeString) | \(videoTimeString) video]")
        }

        log.append(" from \(newMessage.nickname)")

        Logger.verbose(log)

        downStreamProxyInput?.publish(newMessage: newMessage)
    }

    func publish(messageUpdated message: ChatMessageType) {
        log.verbose("Recieved update for message with id: \(message.id)")
        downStreamProxyInput?.publish(messageUpdated: message)
    }

    func deleteMessage(channel: String, messageId: ChatMessageID) {
        downStreamProxyInput?.deleteMessage(channel: channel, messageId: messageId)
    }
}
