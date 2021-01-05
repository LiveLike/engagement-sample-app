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
    static var programId: Name = "Program ID"
    static var programName: Name = "Program Title"
    static var league: Name = "League"
    static var sport: Name = "Sport"
    static var nickname: Name = "Nickname"
    static var deviceOrientation: Name = "Device Orientation"
    static var appOpenCount: Name = "App Open Count"
    static var timeOfLastChatMessage: Name = "Time Of Last Chat Message"
    static var timeOfLastEmoji: Name = "Time Of Last Emoji"
    static var chatStatus: Name = "Chat Status"
    static var widgetStatus: Name = "Widget Status"
    static var officialAppName: Name = "Official App Name"
    static var sdkVersion: Name = "SDK Version"
    static var lifetimePoints: Name = "Lifetime Points"
    static var pointsThisProgram: Name = "Points This Program"
    static var badgeLevelThisProgram: Name = "Badge Level This Program"
    static var timeOfLastBadgeAward: Name = "Time of Last Badge Award"
    static var userMuteState: Name = "User Mute State"
}

extension SuperProperty {
    static func timeOfLastWidgetReceipt(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastWidgetReceipt, value: time)
    }
    
    static func timeOfLastWidgetInteraction(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastWidgetInteraction, value: time)
    }
    
    static func programId(id: String) -> SuperProperty {
        return SuperProperty(name: .programId, value: id)
    }
    
    static func programName(name: String) -> SuperProperty {
        return SuperProperty(name: .programName, value: name)
    }
    
    static func league(leagueName: String) -> SuperProperty {
        return SuperProperty(name: .league, value: leagueName)
    }
    
    static func sport(sportName: String) -> SuperProperty {
        return SuperProperty(name: .sport, value: sportName)
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
    
    static func chatStatus(status: ChatStatus) -> SuperProperty {
        return SuperProperty(name: .chatStatus, value: status.analyticsName)
    }
    
    static func widgetStatus(status: WidgetStatus) -> SuperProperty {
        return SuperProperty(name: .widgetStatus, value: status.analyticsName)
    }
    
    static func officialAppName(officialAppName: String) -> SuperProperty {
        return SuperProperty(name: .officialAppName, value: officialAppName)
    }
    
    static func sdkVersion(version: String) -> SuperProperty {
        return SuperProperty(name: .sdkVersion, value: version)
    }
    
    static func lifetimePoints(points: Int) -> SuperProperty {
        return SuperProperty(name: .lifetimePoints, value: points)
    }
    
    static func pointsThisProgram(points: Int) -> SuperProperty {
        return SuperProperty(name: .pointsThisProgram, value: points)
    }
    
    static func badgeLevelThisProgram(level: Int) -> SuperProperty {
        return SuperProperty(name: .badgeLevelThisProgram, value: level)
    }
    
    static func timeOfLastBadgeAward(time: Date) -> SuperProperty {
        return SuperProperty(name: .timeOfLastBadgeAward, value: time)
    }
    
    static func userMuteState(_ state: UserMuteState) -> SuperProperty {
        return .init(name: .userMuteState, value: state.analyticsName)
    }
}

enum WidgetStatus {
    case enabled
    case disabled

    var analyticsName: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        }
    }
}
