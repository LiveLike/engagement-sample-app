//
//  ConnectionStatus.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-24.
//

import Foundation

/// Connection Status from server or any non-request related client state changes.
///
/// - error: `Error` describing non-requested state change
/// - connected: Status describing requested state change
enum ConnectionStatus {
    case error(description: String)
    case connected(description: String)
}
