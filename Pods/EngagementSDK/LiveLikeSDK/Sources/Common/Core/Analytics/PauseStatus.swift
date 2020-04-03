//
//  PauseStatus.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/29/19.
//

import Foundation

enum PauseStatus {
    case paused
    case unpaused
}

extension PauseStatus {
    var analyticsName: String {
        switch self {
        case .paused:
            return "Paused"
        case .unpaused:
            return "Unpaused"
        }
    }
}
