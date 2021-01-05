//
//  AnalyticsEvent.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import Foundation

extension AnalyticsEvent {
    struct Attribute: ExpressibleByStringLiteral, Equatable, Hashable, CustomStringConvertible {
        let stringValue: String
        init(stringLiteral value: String) {
            stringValue = value
        }

        var description: String { return stringValue }
    }
}

extension AnalyticsEvent.Attribute {
    typealias Attribute = AnalyticsEvent.Attribute
    static let widgetType: Attribute = "Widget Type"
    static let widgetId: Attribute = "Widget ID"
    static let programId: Attribute = "Program ID"
    static let widgetLinkUrl: Attribute = "Link URL"
    static let dismissAction: Attribute = "Dismiss Action"
    static let dismissSecondsSinceStart: Attribute = "Dismiss Seconds Since Start"
    static let interactableState: Attribute = "Interactable State"
    static let messagesScrolledThrough: Attribute = "# of Messages Scrolled Through"
    static let maxReached: Attribute = "Max Reached"
    static let returnMethod: Attribute = "Return Method"
    static let firstTapTime: Attribute = "First Tap Time"
    static let lastTapTime: Attribute = "Last Tap Time"
    static let numberOfTaps: Attribute = "Number Of Taps"
    static let dismissSecondsSinceLastTap: Attribute = "Dismiss Seconds Since Last Tap"
    static let previousOrientation: Attribute = "Previous Orientation"
    static let newOrientation: Attribute = "New Orientation"
    static let totalSecondsInPreviousOrientation: Attribute = "Total Seconds In Previous Orientation"
    static let chatCharacterLength: Attribute = "Character Length"
    static let chatMessageId: Attribute = "Chat Message ID"
    static let chatRoomId: Attribute = "Chat Room ID"
    static let stickerShortcodes: Attribute = "Sticker Shortcodes"
    static let stickerCount: Attribute = "Sticker Count"
    static let stickerKeyboardIndices: Attribute = "Sticker Keyboard Indices"
    static let keyboardType: Attribute = "Keyboard Type"
    static let keyboardHideMethod: Attribute = "Keyboard Hide Method"
    static let previousPauseStatus: Attribute = "Previous Pause Status"
    static let newPauseStatus: Attribute = "New Pause Status"
    static let secondsInPreviousPauseStatus: Attribute = "Seconds In Previous Pause Status"
    static let previousVisibilityStatus: Attribute = "Previous Visibility Status"
    static let newVisibilityStatus: Attribute = "New Visibility Status"
    static let secondsInPreviousVisibilityStatus: Attribute = "Seconds In Previous Visibility Status"
    static let completionType: Attribute = "Completion Type"
    static let pointsEarned: Attribute = "Points Earned"
    static let levelEarned: Attribute = "Level Earned"
    static let badgeEarned: Attribute = "Badge Earned"
    static let pointsInCurrentLevel: Attribute = "Points In Current Level"
    static let pointsToNextLevel: Attribute = "Points To Next Level"
    static let chatMessageHasExternalImage: Attribute = "Has External Image"
    static let alertId: Attribute = "Alert Id"
}
