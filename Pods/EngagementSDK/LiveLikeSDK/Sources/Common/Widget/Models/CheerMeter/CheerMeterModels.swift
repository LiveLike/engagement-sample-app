//
//  CheerMeterModels.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/7/19.
//

import Foundation

struct CheerMeterCreated: Codable {
    let id: String
    let programId: String
    let programDateTime: Date?
    let kind: WidgetKind
    var impressionUrl: URL?
    var rewardsUrl: URL?

    let question: String
    let options: [CheerOption]
    let timeout: Timeout
    let customData: String?

    let subscribeChannel: String
    let createdAt: Date
    let publishedAt: Date?
}

struct CheerOption: Codable {
    let id: String
    let description: String
    let imageUrl: URL
    let voteUrl: URL
    let voteCount: Int
}

struct CheerMeterResults: Decodable {
    let id: String
    let options: [CheerMeterResult]
}

struct CheerMeterResult: Decodable {
    let id: String
    let voteCount: Int
}
