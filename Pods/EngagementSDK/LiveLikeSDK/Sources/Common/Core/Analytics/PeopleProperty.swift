//
//  PeopleProperty.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/18/19.
//

import Foundation

enum PeopleProperty {
    case name(name: String)
    case firstInteractionTime(date: Date)
    case lastInteractionTime(date: Date)
    case sdkVersion(sdkVersion: String)
    case nickname(nickname: String)
    case lastDeviceOrientation(orientation: Orientation)
    case operatingSystem(os: String)
    case timeOfLastWidgetReceipt(time: Date)
    case timeOfLastWidgetInteraction(time: Date)
    case officialAppName(officialAppName: String)
    case lastChatStatus(status: ChatStatus)
    case timeOfLastChatMessage(time: Date)
    case lastWidgetStatus(status: WidgetStatus)
    case lifetimePoints(points: Int)
    case lastProgramID(programID: String)
    case lastProgramName(name: String)
    case userMuteState(UserMuteState)

    var name: String {
        switch self {
        case .name:
            return "$name" // Mixpanel's special property for Name
        case .firstInteractionTime:
            return "First Interaction Time"
        case .lastInteractionTime:
            return "Last Interaction Time"
        case .sdkVersion:
            return "SDK Version"
        case .nickname:
            return "Nickname"
        case .lastDeviceOrientation:
            return "Last Device Orientation"
        case .operatingSystem:
            return "Operating System"
        case .timeOfLastWidgetReceipt:
            return "Time Of Last Widget Receipt"
        case .timeOfLastWidgetInteraction:
            return "Time Of Last Widget Interaction"
        case .officialAppName:
            return "Official App Name"
        case .lastChatStatus:
            return "Last Chat Status"
        case .timeOfLastChatMessage:
            return "Time Of Last Chat Message"
        case .lastWidgetStatus:
            return "Last Widget Status"
        case .lifetimePoints:
            return "Lifetime Points"
        case .lastProgramID:
            return "Last Program ID"
        case .lastProgramName:
            return "Last Program Name"
        case .userMuteState:
            return "User Mute State"
        }
    }

    var value: Any {
        switch self {
        case let .name(name):
            return name
        case let .firstInteractionTime(date):
            return date
        case let .lastInteractionTime(date):
            return date
        case let .sdkVersion(sdkVersion):
            return sdkVersion
        case let .nickname(nickname):
            return nickname
        case let .lastDeviceOrientation(orientation):
            return orientation.rawValue
        case let .operatingSystem(os):
            return os
        case let .timeOfLastWidgetReceipt(time):
            return time
        case let .timeOfLastWidgetInteraction(time):
            return time
        case let .officialAppName(officialAppName):
            return officialAppName
        case let .lastChatStatus(status):
            return status.analyticsName
        case let .timeOfLastChatMessage(time):
            return time
        case let .lastWidgetStatus(status):
            return status.analyticsName
        case let .lifetimePoints(points):
            return points
        case let .lastProgramID(programID):
            return programID
        case let .lastProgramName(name):
            return name
        case let .userMuteState(state):
            return state.analyticsName
        }
    }
}
