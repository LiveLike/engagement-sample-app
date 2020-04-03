//
//  ChatScrollCompletedProperties.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-23.
//

import Foundation

struct ChatScrollCompletedProperties {
    var messagesScrolledThrough: Int
    var maxReached: Bool
    var returnMethod: ChatScrollingReturnMethod
}

enum ChatScrollingReturnMethod: String {
    case scroll = "Scroll"
    case snapToLive = "Snap To Live Button"
    case keyboard = "Keyboard"
}
