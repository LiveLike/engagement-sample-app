//
//  VisibilityStatus.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/29/19.
//

import Foundation

enum VisibilityStatus {
    case shown
    case hidden
}

extension VisibilityStatus {
    var analyticsName: String {
        switch self {
        case .shown:
            return "Shown"
        case .hidden:
            return "Hidden"
        }
    }
}
