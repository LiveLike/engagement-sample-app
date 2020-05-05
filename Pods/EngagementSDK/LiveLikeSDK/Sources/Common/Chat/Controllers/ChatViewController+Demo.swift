//
//  ChatViewController+Demo.swift
//  EngagementSDKDemo
//
//  Created by Jelzon Monzon on 2/12/20.
//

import Foundation

/// Public methods for the EngagementSDKDemo framework for demo and testing purposes
public extension ChatViewController {
    func appendMessageToMessagesList(_ message: String){
        let user = ChatUser(
            userId: ChatUser.ID(idString: UUID().uuidString),
            isActive: false,
            isLocalUser: false,
            nickName: "tester",
            friendDiscoveryKey: nil,
            friendName: nil,
            badgeImageURL: nil
        )
        let chatMessageType = ChatMessage(
            id: ChatMessageID(UUID().uuidString),
            roomID: "room-id",
            message: message,
            sender: user,
            videoTimestamp: nil,
            reactions: ReactionVotes(allVotes: []),
            timestamp: Date(),
            profileImageUrl: nil,
            createdAt: TimeToken(pubnubTimetoken: 0),
            bodyImageUrl: nil,
            bodyImageSize: nil
        )
        self.chatAdapter?.publish(newMessage: chatMessageType)
    }
}
