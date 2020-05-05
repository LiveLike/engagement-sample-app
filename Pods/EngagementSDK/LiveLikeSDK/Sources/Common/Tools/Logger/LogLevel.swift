//
//  LogLevel.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-09.
//

import Foundation

/**
 `Level` gives the integrator the ability to specify the level of detail to be logged to Apple's unified logging system.

 Defaults to `none`.
 */
@objc
public enum LogLevel: Int {
    /**
     Highly detailed level of logging, best used when trying to understand the working of a specific section/feature of the Engagement SDK.
     */
    @objc(Verbose)
    case verbose = 0

    /**
     Information that is diagnostically helpful to integrators and Engagement SDK developers.
     */
    @objc(Debug)
    case debug = 1

    /**
     Information that is always useful to have, but not vital.
     */
    @objc(Info)
    case info = 2

    /**
     Information related to events that could potentially cause oddities, but the Engagement SDK will continue working as expected.
     */
    @objc(Warning)
    case warning = 3

    /**
     An error occured that is fatal to a specific operation/component, but not the overall Engagement SDK.
     */
    @objc(Error)
    case error = 4

    /**
     A fatal issue occured, from which the Engagement SDK cannot recover.
     */
    @objc(Severe)
    case severe = 5

    /**
     No logging enabled.

     - note: This is the default logging level, to avoid cluttering the integrators logs.
     */
    @objc(None)
    case none = 6
}

extension LogLevel {
    var name: String {
        switch self {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "⚠️WARNING"
        case .error:
            return "❌ERROR"
        case .severe:
            return "❌❌❌SEVERE"
        default:
            return ""
        }
    }
}
