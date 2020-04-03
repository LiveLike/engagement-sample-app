//
//  TextPredictionCreated.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-04.
//

import Foundation

struct TextPredictionCreatedOption: Decodable {
    let description: String
    let id: String
    let voteUrl: URL
}

struct TextPredictionCreated: Decodable {
    let confirmationMessage: String
    let createdAt: Date
    let followUpUrl: URL
    let id: String
    let kind: WidgetKind
    let options: [TextPredictionCreatedOption]
    let programId: String
    let question: String
    let subscribeChannel: String
    let timeout: TimeInterval
    let url: URL
    let programDateTime: Date?
    var impressionUrl: URL?
    var rewardsUrl: URL?

    let animationTimerAsset: String = "timer"
    let animationConfirmationAsset: String = AnimationAssets.randomConfirmationEmojiAsset()

    enum CodingKeys: String, CodingKey {
        case confirmationMessage
        case createdAt
        case followUpUrl
        case id
        case kind
        case options
        case programId
        case question
        case subscribeChannel
        case timeout
        case impressionUrl
        case rewardsUrl
        case url
        case programDateTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confirmationMessage = try container.decode(String.self, forKey: .confirmationMessage)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        followUpUrl = try container.decode(URL.self, forKey: .followUpUrl)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(WidgetKind.self, forKey: .kind)
        options = try container.decode([TextPredictionCreatedOption].self, forKey: .options)
        programId = try container.decode(String.self, forKey: .programId)
        question = try container.decode(String.self, forKey: .question)
        subscribeChannel = try container.decode(String.self, forKey: .subscribeChannel)
        let iso8601Duration = try container.decode(String.self, forKey: .timeout)
        timeout = iso8601Duration.timeIntervalFromISO8601Duration() ?? 7 // use a default of 7 seconds if this parsing fails
        impressionUrl = try? container.decode(URL.self, forKey: .impressionUrl)
        rewardsUrl = try? container.decode(URL.self, forKey: .rewardsUrl)
        url = try container.decode(URL.self, forKey: .url)
        programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
    }
}
