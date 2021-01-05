//
//  ChatAdapter+Analytics.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 9/13/19.
//

import Foundation

// MARK: - Analytics

internal extension AnalyticsEvent {

    static func chatMessageDisplayed(for message: MessageViewModel) -> AnalyticsEvent {
        return .init(
            name: .chatMessageDisplayed,
            data: [
                .chatMessageID: message.id.asString,
                .stickerShortcodes: message.stickerShortcodesInMessage.map({ ":\($0):"})
            ]
        )
    }

    static func chatFlagButtonPressed(for message: MessageViewModel) -> AnalyticsEvent {
        return .init(name: .chatFlagButtonPressed, data: [
            .targetChatMessageID: message.id.asString,
            .targetUserProfileID: senderIDAttributeValue(for: message)
            ])
    }
    
    static func chatFlagActionSelected(for message: MessageViewModel, action: ChatActionResult) -> AnalyticsEvent {
        return .init(name: .chatFlagActionSelected, data: [
            .targetChatMessageID: message.id.asString,
            .targetUserProfileID: senderIDAttributeValue(for: message),
            .selectedAction: action.analyticsValue
            ])
    }
    
    static func chatReactionPanelOpened(for message: MessageViewModel) -> AnalyticsEvent {
        return .init(name: .chatReactionPanelOpened, data: [.chatMessageID: message.id.asString])
    }
    
    static func chatReactionAdded(for message: MessageViewModel, reactionId: ReactionID) -> AnalyticsEvent {
        return .init(name: .chatReactionAdded, data: [.chatMessageID: message.id.asString,
                                                      .chatReactionID: reactionId.asString,
                                                      .chatRoomID: message.chatRoomId])
    }
    
    static func chatReactionRemoved(for message: MessageViewModel, reactionId: ReactionID) -> AnalyticsEvent {
        return .init(name: .chatReactionRemoved, data: [.chatMessageID: message.id.asString,
                                                        .chatReactionID: reactionId.asString,
                                                        .chatRoomID: message.chatRoomId])
       }
    
    static func senderIDAttributeValue(for message: MessageViewModel) -> String {
        if let senderIDUnwrapped = message.sender?.id.asString {
            return senderIDUnwrapped
        } else {
            assertionFailure("Flagging a message with no sender ID should be impossible")
            return "Unknown sender"
        }
    }
}

extension ChatAdapter {
    func recordChatFlagButtonPressed(for messageViewModel: MessageViewModel) {
        eventRecorder.record(.chatFlagButtonPressed(for: messageViewModel))
    }
    
    func recordChatFlagActionSelected(for messageViewModel: MessageViewModel, result: ChatActionResult) {
        defer {
            eventRecorder.record(.chatFlagActionSelected(for: messageViewModel, action: result))
        }
        
        switch result {
        case let .blocked(userID: userID, dueTo: messageViewModel):
            self.blockList.block(userWithID: userID)
            fallthrough // The blocking action implies reporting as well per IOSSDK-408 definition
            
        case let .reported(message: messageViewModel):
            self.chatSession.reportMessage(withID: messageViewModel.id) { result in
                switch result {
                case .success:
                    log.info("Message Reported for message with id: \(messageViewModel.id.asString)")
                case .failure(let error):
                    log.error("Failed to report message with id: \(messageViewModel.id.asString) due to error \(error)")
                }
            }
        case .cancelled:
            break
        }
    }
    
    func recordChatReactionPanelOpened(for messageViewModel: MessageViewModel) {
        eventRecorder.record(.chatReactionPanelOpened(for: messageViewModel))
    }

    func recordChatReactionAdded(for message: MessageViewModel, reactionId: ReactionID) {
        eventRecorder.record(.chatReactionAdded(for: message, reactionId: reactionId))
    }
    
    func recordChatReactionRemoved(for message: MessageViewModel, reactionId: ReactionID) {
        eventRecorder.record(.chatReactionRemoved(for: message, reactionId: reactionId))
    }
}

private extension AnalyticsEvent.Name {
    static let chatMessageDisplayed: Name = "Chat Message Displayed"
    static let chatFlagButtonPressed: Name = "Chat Flag Button Pressed"
    static let chatFlagActionSelected: Name = "Chat Flag Action Selected"
    static let chatReactionPanelOpened: Name = "Chat Reaction Panel Opened"
    static let chatReactionSelected: Name = "Chat Reaction Selected"
    static let chatReactionAdded: Name = "Chat Reaction Added"
    static let chatReactionRemoved: Name = "Chat Reaction Removed"
}

private extension AnalyticsEvent.Attribute {
    static let targetChatMessageID: Attribute = "Target Chat Message ID"
    static let targetUserProfileID: Attribute = "Target User Profile ID"
    static let selectedAction: Attribute = "Selected Action"
    static let chatMessageID: Attribute = "Chat Message ID"
    static let chatReactionID: Attribute = "Chat Reaction ID"
    static let chatReactionAction: Attribute = "Reaction Action"
    static let chatRoomID: Attribute = "Chat Room ID"
}

private extension ChatActionResult {
    var analyticsValue: String {
        switch self {
        case .cancelled:
            return "Cancel"
        case .blocked:
            return "Block"
        case .reported:
            return "Report"
        }
    }
}
