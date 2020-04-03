//
//  TimeToken.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

/// Represents a UTC time
struct TimeToken {
    var pubnubTimetoken: NSNumber
    var date: Date

    init(pubnubTimetoken: NSNumber) {
        self.pubnubTimetoken = pubnubTimetoken
        self.date = Date(timeIntervalSince1970: TimeInterval(truncating: pubnubTimetoken) / 10_000_000)
    }
}
