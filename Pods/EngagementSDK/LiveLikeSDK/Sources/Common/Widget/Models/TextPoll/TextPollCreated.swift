//
//  TextPollCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/19/19.
//

import Foundation

struct TextPollCreated: Decodable {
    var id: String
    var question: String
    var options: [TextPollOption]
    var timeout: Timeout
    var subscribeChannel: String
    var programId: String
    var programDateTime: Date?
    var kind: WidgetKind
    var impressionUrl: URL?
    var rewardsUrl: URL?
    var customData: String?
}

struct TextPollOption: Decodable {
    var id: String
    var description: String
    var voteCount: Int
    var voteUrl: URL
}
