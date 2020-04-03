//
//  ImagePollCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/14/19.
//

import Foundation

typealias Timeout = String

extension Timeout {
    var timeInterval: TimeInterval {
        return timeIntervalFromISO8601Duration() ?? 7
    }
}

struct ImagePollCreated: Decodable {
    var id: String
    var question: String
    var options: [ImagePollOption]
    var timeout: Timeout
    var subscribeChannel: String
    var programId: String
    var programDateTime: Date?
    var kind: WidgetKind
    var impressionUrl: URL?
    var rewardsUrl: URL?

    let animationTimerAsset: String = "timer"
}

struct ImagePollOption: Decodable {
    var id: String
    var description: String
    var imageUrl: URL
    var voteCount: Int
    var voteUrl: URL
}
