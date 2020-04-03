//
//  AnimationAssets.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-06.
//

import Foundation

struct AnimationAssets {
    private static let confirmationAnimationAssets = ["emoji-cool", "emoji-devil", "emoji-happy", "emoji-nerd"]
    static func randomConfirmationEmojiAsset() -> String {
        return confirmationAnimationAssets.randomElement()!
    }

    static var widgetTimer: String {
        return "timer"
    }
}
