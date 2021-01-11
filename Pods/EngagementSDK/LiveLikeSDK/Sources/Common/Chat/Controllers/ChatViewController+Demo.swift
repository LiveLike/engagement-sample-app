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
        guard let chatSession = self.messageViewController.chatSession else { return }

        let user = ChatUser(
            userId: ChatUser.ID(idString: UUID().uuidString),
            isActive: false,
            isLocalUser: false,
            nickName: "tester",
            friendDiscoveryKey: nil,
            friendName: nil
        )
        let chatMessageType = ChatMessage(
            id: ChatMessageID(UUID().uuidString),
            roomID: "room-id",
            channelName: "channel-name",
            message: message,
            sender: user,
            videoTimestamp: nil,
            reactions: ReactionVotes(allVotes: []),
            timestamp: Date(),
            profileImageUrl: nil,
            createdAt: TimeToken(pubnubTimetoken: 0),
            bodyImageUrl: nil,
            bodyImageSize: nil,
            filteredMessage: nil,
            filteredReasons: Set()
        )
        self.messageViewController.chatSession(chatSession, didRecieveNewMessage: chatMessageType)
    }

    func sendReaction(index: Int) {
        guard let chatSession = self.messageViewController.chatSession else { return }
        guard let message = chatSession.messages.last else { return }

        let currentReactionView = message.reactions.allVotes.first(where: { $0.isMine })?.voteID

        firstly {
            chatSession.reactionsVendor.getReactions()
        }.then { reactions -> Promise<Void> in
            guard let reactionID = reactions[safe: index]?.id else { return Promise(error: NilError() )}
            return chatSession.sendMessageReaction(
                message.id,
                reaction: reactionID,
                reactionsToRemove: currentReactionView
            )
        }.then {
            print("done")
        }.catch {
            print($0)
        }
    }
}
