//
//  TextPredictionFollowUp.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-05.
//

import Foundation

struct TextPredictionFollowUpOption: Decodable {
    let voteCount: Int
    let voteUrl: URL
    let description: String
    let id: String
    let isCorrect: Bool
}

struct TextPredictionFollowUp: Decodable {
    let id: String
    let createdAt: Date
    let kind: WidgetKind
    let options: [TextPredictionFollowUpOption]
    let programId: String
    let question: String
    let subscribeChannel: String
    let textPredictionUrl: URL
    let timeout: TimeInterval
    let url: URL
    let programDateTime: Date?
    var impressionUrl: URL?
    var rewardsUrl: URL?

    enum CodingKeys: String, CodingKey {
        case id = "textPredictionId"
        case createdAt
        case kind
        case options
        case programId
        case question
        case subscribeChannel
        case textPredictionUrl
        case timeout
        case impressionUrl
        case rewardsUrl
        case url
        case programDateTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        kind = try container.decode(WidgetKind.self, forKey: .kind)
        options = try container.decode([TextPredictionFollowUpOption].self, forKey: .options)
        programId = try container.decode(String.self, forKey: .programId)
        question = try container.decode(String.self, forKey: .question)
        subscribeChannel = try container.decode(String.self, forKey: .subscribeChannel)
        textPredictionUrl = try container.decode(URL.self, forKey: .textPredictionUrl)
        let iso8601Duration = try container.decode(String.self, forKey: .timeout)
        timeout = iso8601Duration.timeIntervalFromISO8601Duration() ?? 7 // use a default of 7 seconds if this parsing fails
        impressionUrl = try? container.decode(URL.self, forKey: .impressionUrl)
        rewardsUrl = try? container.decode(URL.self, forKey: .rewardsUrl)
        url = try container.decode(URL.self, forKey: .url)
        programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
    }
}

extension TextPredictionFollowUp {
    var correctOptionsIds: [String] {
        return options
            .filter({ $0.isCorrect })
            .map({ $0.id })
    }
}
