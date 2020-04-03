//
//  UserMuteState.swift
//  EngagementSDK
//

enum UserMuteState: String {
    case shadowMuted = "Shadow Muted"
    case unmuted = "None"
    var analyticsName: String { return rawValue }
}
