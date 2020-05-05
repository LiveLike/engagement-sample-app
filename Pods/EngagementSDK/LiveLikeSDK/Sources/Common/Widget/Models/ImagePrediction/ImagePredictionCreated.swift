//
//  File.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/14/19.
//

import Foundation

struct ImagePredictionOption: Decodable {
    let voteCount: Int
    let voteUrl: URL
    let imageUrl: URL
    let description: String
    let id: String
}

struct ImagePredictionCreated: Decodable {
    let id: String
    let url: URL
    let question: String
    let options: [ImagePredictionOption]
    let confirmationMessage: String
    let timeout: TimeInterval
    let subscribeChannel: String
    let programId: String
    let programDateTime: Date?
    var impressionUrl: URL?
    var rewardsUrl: URL?
    var customData: String?

    var createdAt: Date = Date()

    var kind: WidgetKind

    let animationConfirmationAsset: String = AnimationAssets.randomConfirmationEmojiAsset()

    enum CodingKeys: String, CodingKey {
        case confirmationMessage
        case followUpUrl
        case id
        case kind
        case options
        case programId
        case question
        case subscribeChannel
        case timeout
        case url
        case programDateTime
        case impressionUrl
        case rewardsUrl
        case customData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confirmationMessage = try container.decode(String.self, forKey: .confirmationMessage)
        id = try container.decode(String.self, forKey: .id)
        options = try container.decode([ImagePredictionOption].self, forKey: .options)
        programId = try container.decode(String.self, forKey: .programId)
        question = try container.decode(String.self, forKey: .question)
        subscribeChannel = try container.decode(String.self, forKey: .subscribeChannel)
        kind = try container.decode(WidgetKind.self, forKey: .kind)
        let iso8601Duration = try container.decode(String.self, forKey: .timeout)
        timeout = iso8601Duration.timeIntervalFromISO8601Duration() ?? 7 // use a default of 7 seconds if this parsing fails
        impressionUrl = try? container.decode(URL.self, forKey: .impressionUrl)
        url = try container.decode(URL.self, forKey: .url)
        programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
        rewardsUrl = try? container.decode(URL.self, forKey: .rewardsUrl)
        customData = try? container.decode(String.self, forKey: .customData)
    }
}
