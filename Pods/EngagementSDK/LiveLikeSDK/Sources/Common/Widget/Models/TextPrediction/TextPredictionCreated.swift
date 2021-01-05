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
    let voteCount: Int

    internal init(description: String, id: String, voteUrl: URL, voteCount: Int) {
        self.description = description
        self.id = id
        self.voteUrl = voteUrl
        self.voteCount = voteCount
    }
}

struct TextPredictionCreated: Decodable {
    let confirmationMessage: String
    let createdAt: Date
    let publishedAt: Date?
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
    let impressionUrl: URL?
    let rewardsUrl: URL?
    let customData: String?

    let animationConfirmationAsset: String = AnimationAssets.randomConfirmationEmojiAsset()

    enum CodingKeys: String, CodingKey {
        case confirmationMessage
        case createdAt
        case publishedAt
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
        case customData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confirmationMessage = try container.decode(String.self, forKey: .confirmationMessage)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        publishedAt = try? container.decode(Date.self, forKey: .publishedAt)
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
        customData = try? container.decode(String.self, forKey: .customData)
    }

    internal init(confirmationMessage: String, createdAt: Date, publishedAt: Date?, followUpUrl: URL, id: String, kind: WidgetKind, options: [TextPredictionCreatedOption], programId: String, question: String, subscribeChannel: String, timeout: TimeInterval, url: URL, programDateTime: Date?, impressionUrl: URL? = nil, rewardsUrl: URL? = nil, customData: String? = nil) {
        self.confirmationMessage = confirmationMessage
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.followUpUrl = followUpUrl
        self.id = id
        self.kind = kind
        self.options = options
        self.programId = programId
        self.question = question
        self.subscribeChannel = subscribeChannel
        self.timeout = timeout
        self.url = url
        self.programDateTime = programDateTime
        self.impressionUrl = impressionUrl
        self.rewardsUrl = rewardsUrl
        self.customData = customData
    }
}
