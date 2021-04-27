//
//  SuperProperty.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/19/19.
//

import Foundation

struct SuperProperty {
    let name: Name
    let value: Any
    
    init(name: Name, value: Any){
        self.name = name
        self.value = value
    }
}

extension SuperProperty {
    struct Name: ExpressibleByStringLiteral, Equatable {
        let stringValue: String
        init(stringLiteral value: String) {
            self.stringValue = value
        }
    }
}

extension SuperProperty.Name {
    typealias Name = SuperProperty.Name
    static var timeOfLastWidgetReceipt: Name = "Time Of Last Widget Receipt"
    static var timeOfLastWidgetInteraction: Name = "Time Of Last Widget Interaction"
    static var nickname: Name = "Nickname"
    static var deviceOrientation: Name = "Device Orientation"
    static var appOpenCount: Name = "App Open Count"
    static var timeOfLastChatMessage: Name = "Time Of Last Chat Message"
    static var timeOfLastEmoji: Name = "Time Of Last Emoji"
    static var officialAppName: Name = "Official App Name"
    static var sdkVersion: Name = "SDK Version"
}

extension SuperProperty {
    static func timeOfLastWidgetReceipt(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastWidgetReceipt, value: time)
    }
    
    static func timeOfLastWidgetInteraction(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastWidgetInteraction, value: time)
    }
    
    static func nickname(nickname: String) -> SuperProperty{
        return SuperProperty(name: .nickname, value: nickname)
    }
    
    static func deviceOrientation(orientation: Orientation) -> SuperProperty {
        return SuperProperty(name: .deviceOrientation, value: orientation.rawValue)
    }
    
    static func appOpenCount(count: Int) -> SuperProperty {
        return SuperProperty(name: .appOpenCount, value: count)
    }
    
    static func timeOfLastChatMessage(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastChatMessage, value: time)
    }
    
    static func timeOfLastEmoji(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastEmoji, value: time)
    }

    static func officialAppName(officialAppName: String) -> SuperProperty {
        return SuperProperty(name: .officialAppName, value: officialAppName)
    }
    
    static func sdkVersion(version: String) -> SuperProperty {
        return SuperProperty(name: .sdkVersion, value: version)
    }
}
