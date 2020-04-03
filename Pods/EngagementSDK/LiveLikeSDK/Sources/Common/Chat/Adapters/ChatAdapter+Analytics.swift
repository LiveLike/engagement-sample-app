//
//  ChatAdapter+Analytics.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 9/13/19.
//

import Foundation

// MARK: - Analytics

internal extension AnalyticsEvent {
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

    static func chatReactionSelected(for message: MessageViewModel, reaction: ReactionID, isMine: Bool) -> AnalyticsEvent {
        return .init(name: .chatReactionSelected, data: [.chatMessageID: message.id.asString,
                                                         .chatReactionID: reaction.asString,
                                                         .chatReactionAction: isMine ? "Removed" : "Added"])
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
            guard let messageReporter = self.messageReporter else { return }
            
            firstly {
                messageReporter.report(messageViewModel: messageViewModel)
                }.then {
                    log.info("Message Reported for view model \(messageViewModel)")
                }.catch {
                    log.error("Failed to report message for view model \(messageViewModel) due to error \($0)")
            }
            
        case .cancelled:
            break
        }
    }
    
    func recordChatReactionPanelOpened(for messageViewModel: MessageViewModel) {
        eventRecorder.record(.chatReactionPanelOpened(for: messageViewModel))
    }

    func recordChatReactionSelection(for messageViewModel: MessageViewModel, reaction: ReactionID, isMine: Bool) {
        eventRecorder.record(.chatReactionSelected(for: messageViewModel, reaction: reaction, isMine: isMine))
    }
}

private extension AnalyticsEvent.Name {
    static let chatFlagButtonPressed: Name = "Chat Flag Button Pressed"
    static let chatFlagActionSelected: Name = "Chat Flag Action Selected"
    static let chatReactionPanelOpened: Name = "Chat Reaction Panel Opened"
    static let chatReactionSelected: Name = "Chat Reaction Selected"
}

private extension AnalyticsEvent.Attribute {
    static let targetChatMessageID: Attribute = "Target Chat Message ID"
    static let targetUserProfileID: Attribute = "Target User Profile ID"
    static let selectedAction: Attribute = "Selected Action"
    static let chatMessageID: Attribute = "Chat Message ID"
    static let chatReactionID: Attribute = "Chat Reaction ID"
    static let chatReactionAction: Attribute = "Reaction Action"
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
