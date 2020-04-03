//
//  SessionStatus.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-25.
//

import Foundation

/**
 The status of the `ContentSession`.

 The application can register as the `ContentSessionDelegate` to receive notifications when the `SessionState` changes.
 */
@objc
public enum SessionStatus: Int, CustomDebugStringConvertible {
    /// The session has not been initialized
    @objc(LLUninitialized)
    case uninitialized
    /// The session is in the process of initializing. It will not process any events until this has completed.
    /// Any events sent to the session while in this state will be ignored.
    @objc(LLInitializing)
    case initializing
    /// The session is ready to send and receive events.
    @objc(LLReady)
    case ready
    /// An error occurred
    @objc(LLError)
    case error

    public var debugDescription: String {
        switch self {
        case .uninitialized:
            return "uninitialized"
        case .initializing:
            return "initializing"
        case .ready:
            return "ready"
        case .error:
            return "error"
        }
    }
}
