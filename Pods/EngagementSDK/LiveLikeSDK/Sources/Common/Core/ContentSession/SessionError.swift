//
//  SessionError.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-25.
//

import Foundation

enum SessionError: Error, LocalizedError {
    case messagingClientsNotConfigured
    case invalidSessionStatus(SessionStatus)

    var errorDescription: String? {
        switch self {
        case .messagingClientsNotConfigured:
            return "No messaging clients have been configured"
        case let .invalidSessionStatus(status):
            return "Could not complete request. Invalid session status \(status)"
        }
    }
}
