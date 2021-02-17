//
//  AnalyticsEvent.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import Foundation

struct AnalyticsEvent {
    let metadata: [Attribute: Any]
    let name: Name
    let isClientReadable: Bool

    internal init(name: Name, data: [Attribute: Any], isClientReadable: Bool = true) {
        self.name = name
        metadata = data
        self.isClientReadable = isClientReadable
    }
}

extension AnalyticsEvent {
    struct Name: ExpressibleByStringLiteral, Equatable, CustomStringConvertible {
        let stringValue: String
        init(stringLiteral value: String) {
            stringValue = value
        }

        var description: String { return stringValue }
    }
}

extension AnalyticsEvent.Name {
    typealias Name = AnalyticsEvent.Name
    static let widgetDisplayed: Name = "Widget Displayed"
    static let widgetInteracted: Name = "Widget Interacted"
    static let widgetEngaged: Name = "Widget Engaged"
    static let widgetUserDismissed: Name = "Widget Dismissed"
    static let chatScrollInitiated: Name = "Chat Scroll Initiated"
    static let chatScrollCompleted: Name = "Chat Scroll Completed"
    static let chatMessageSent: Name = "Chat Message Sent"
    static let orientationChanged: Name = "Orientation Changed"
    static let keyboardSelected: Name = "Keyboard Selected"
    static let keyboardHidden: Name = "Keyboard Hidden"
    static let widgetPauseStatusChanged: Name = "Widget Pause Status Changed"
    static let widgetVisibilityStatusChanged: Name = "Widget Visibility Status Changed"
    static let chatPauseStatusChanged: Name = "Chat Pause Status Changed"
    static let chatVisibilityStatusChanged: Name = "Chat Visibility Status Changed"
    static let alertWidgetLinkOpened: Name = "Alert Link Opened"
}

extension AnalyticsEvent {
    static func widgetDisplayed(kind: String, widgetId: String, widgetLink: URL?) -> AnalyticsEvent {
        var data: [Attribute: Any] = [.widgetType: kind, .widgetId: widgetId]
        if let widgetLink = widgetLink {
            data[.widgetLinkUrl] = widgetLink.absoluteString
        }
        return AnalyticsEvent(name: .widgetDisplayed,
                              data: data)
    }

    static func widgetEngaged(kind: WidgetKind, id: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: .widgetEngaged,
            data: {
                let props: [Attribute: Any] = [
                    .widgetType: kind.analyticsName,
                    .widgetId: id
                ]
                return props
            }()
        )
    }

    static func widgetInteracted(properties: WidgetInteractedProperties) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: .widgetInteracted,
            data: {
                let props: [Attribute: Any?] = [
                    .widgetType: properties.widgetKind,
                    .widgetId: properties.widgetId,
                    .firstTapTime: properties.firstTapTime,
                    .lastTapTime: properties.lastTapTime,
                    .numberOfTaps: properties.numberOfTaps,
                ]
                return props.compactMapValues { $0 }
            }()
        )
    }

    static func widgetUserDismissed(properties: WidgetDismissedProperties) -> AnalyticsEvent {
        var data: [Attribute: Any] = [
            .widgetType: properties.widgetKind,
            .widgetId: properties.widgetId,
            .dismissAction: properties.dismissAction.rawValue,
            .dismissSecondsSinceStart: properties.dismissSecondsSinceStart,
            .numberOfTaps: properties.numberOfTaps
        ]
        if let interactableState = properties.interactableState {
            data[.interactableState] = interactableState.rawValue
        }
        if let seconds = properties.dismissSecondsSinceLastTap {
            data[.dismissSecondsSinceLastTap] = seconds
        }
        return AnalyticsEvent(name: .widgetUserDismissed,
                              data: data)
    }
    
    static func alertWidgetLinkOpened(alertId: String, programId: String, linkUrl: String) -> AnalyticsEvent {
        return .init(name: .alertWidgetLinkOpened,
                     data: [
                        .alertId: alertId,
                        .programId: programId,
                        .widgetLinkUrl: linkUrl,
                        .widgetType: WidgetKind.alert.analyticsName
        ])
    }

    static var chatScrollInitiated: AnalyticsEvent {
        return AnalyticsEvent(name: .chatScrollInitiated,
                              data: [:])
    }

    static func chatScrollCompleted(properties: ChatScrollCompletedProperties) -> AnalyticsEvent {
        return AnalyticsEvent(name: .chatScrollCompleted,
                              data: [.messagesScrolledThrough: properties.messagesScrolledThrough,
                                     .maxReached: properties.maxReached,
                                     .returnMethod: properties.returnMethod.rawValue])
    }

    static func chatMessageSent(properties: ChatSentMessageProperties) -> AnalyticsEvent {
        return AnalyticsEvent(name: .chatMessageSent,
                              data: [.chatCharacterLength: properties.characterCount,
                                     .chatMessageId: properties.messageId,
                                     .stickerShortcodes: properties.stickerShortcodes,
                                     .stickerCount: properties.stickerCount,
                                     .stickerKeyboardIndices: properties.stickerIndices,
                                     .chatMessageHasExternalImage: properties.hasExternalImage,
                                     .chatRoomId: properties.chatRoomId])
    }

    static func orientationChanged(previousOrientation: Orientation, newOrientation: Orientation, secondsInPreviousOrientation: Double) -> AnalyticsEvent {
        return AnalyticsEvent(name: .orientationChanged,
                              data: [
                                  .previousOrientation: previousOrientation.rawValue,
                                  .newOrientation: newOrientation.rawValue,
                                  .totalSecondsInPreviousOrientation: secondsInPreviousOrientation
                              ])
    }

    static func keyboardSelected(properties: KeyboardType) -> AnalyticsEvent {
        return AnalyticsEvent(name: .keyboardSelected,
                              data: [
                                  .keyboardType: properties.name
                              ])
    }

    static func keyboardHidden(properties: KeyboardHiddenProperties) -> AnalyticsEvent {
        var data: [Attribute: Any] = [
            .keyboardType: properties.keyboardType.name,
            .keyboardHideMethod: properties.keyboardHideMethod.name
        ]
        if let messageID = properties.messageID {
            data[.chatMessageId] = messageID
        }
        return AnalyticsEvent(name: .keyboardHidden,
                              data: data)
    }

    static func widgetPauseStatusChanged(previousStatus: PauseStatus, newStatus: PauseStatus, secondsInPreviousStatus: Double) -> AnalyticsEvent {
        return AnalyticsEvent(name: .widgetPauseStatusChanged,
                              data: [
                                  .previousPauseStatus: previousStatus.analyticsName,
                                  .newPauseStatus: newStatus.analyticsName,
                                  .secondsInPreviousPauseStatus: secondsInPreviousStatus
                              ])
    }

    static func widgetVisibilityStatusChanged(previousStatus: VisibilityStatus, newStatus: VisibilityStatus, secondsInPreviousStatus: Double) -> AnalyticsEvent {
        return AnalyticsEvent(name: .widgetVisibilityStatusChanged,
                              data: [
                                  .previousVisibilityStatus: previousStatus.analyticsName,
                                  .newVisibilityStatus: newStatus.analyticsName,
                                  .secondsInPreviousVisibilityStatus: secondsInPreviousStatus
                              ])
    }

    static func chatPauseStatusChanged(previousStatus: PauseStatus, newStatus: PauseStatus, secondsInPreviousStatus: Double) -> AnalyticsEvent {
        return AnalyticsEvent(name: .chatPauseStatusChanged,
                              data: [
                                  .previousPauseStatus: previousStatus.analyticsName,
                                  .newPauseStatus: newStatus.analyticsName,
                                  .secondsInPreviousPauseStatus: secondsInPreviousStatus
                              ])
    }

    static func chatVisibilityStatusChanged(previousStatus: VisibilityStatus, newStatus: VisibilityStatus, secondsInPreviousStatus: Double) -> AnalyticsEvent {
        return AnalyticsEvent(name: .chatVisibilityStatusChanged,
                              data: [
                                  .previousVisibilityStatus: previousStatus.analyticsName,
                                  .newVisibilityStatus: newStatus.analyticsName,
                                  .secondsInPreviousVisibilityStatus: secondsInPreviousStatus
                              ])
    }
}
