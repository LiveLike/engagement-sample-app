//
//  ChatStatus.swift
//  EngagementSDK
//

enum ChatStatus {
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
