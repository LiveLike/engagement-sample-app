//
//  KeyboardProperties.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-29.
//

import Foundation

struct KeyboardHiddenProperties {
    let keyboardType: KeyboardType
    let keyboardHideMethod: KeyboardHideMethodType
    let messageID: String?
}

enum KeyboardType {
    case standard
    case sticker

    var name: String {
        switch self {
        case .standard:
            return "Standard"
        case .sticker:
            return "Sticker"
        }
    }
}

enum KeyboardHideMethodType {
    case messageSent
    case changedType
    case resignedResponder
    case emptySend

    var name: String {
        switch self {
        case .messageSent:
            return "Sent Message"
        case .changedType:
            return "Dismissed Via Changing Keyboard Type"
        case .resignedResponder:
            return "Dismissed Via Tap Outside"
        case .emptySend:
            return "Dismissed Via Send Button"
        }
    }
}
