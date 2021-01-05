//
//  ImagePredictionFollowUp.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/22/19.
//

import Foundation

struct ImagePredictionFollowUpOption: Decodable {
    let voteCount: Int
    let voteUrl: URL
    let imageUrl: URL
    let description: String
    let id: String
    let isCorrect: Bool
}

struct ImagePredictionFollowUp: Decodable {
    let id: String
    let createdAt: Date
    let publishedAt: Date?
    let kind: WidgetKind
    let options: [ImagePredictionFollowUpOption]
    let programId: String
    let question: String
    let subscribeChannel: String
    let imagePredictionUrl: URL
    let timeout: TimeInterval
    let programDateTime: Date?
    let url: URL
    var impressionUrl: URL?
    var rewardsUrl: URL?
    let customData: String?
    let claimUrl: URL
    let imagePredictionId: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case publishedAt
        case kind
        case options
        case programId
        case question
        case subscribeChannel
        case imagePredictionUrl
        case timeout
        case impressionUrl
        case rewardsUrl
        case url
        case programDateTime
        case customData
        case claimUrl
        case imagePredictionId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        publishedAt = try? container.decode(Date.self, forKey: .publishedAt)
        kind = try container.decode(WidgetKind.self, forKey: .kind)
        options = try container.decode([ImagePredictionFollowUpOption].self, forKey: .options)
        programId = try container.decode(String.self, forKey: .programId)
        question = try container.decode(String.self, forKey: .question)
        subscribeChannel = try container.decode(String.self, forKey: .subscribeChannel)
        imagePredictionUrl = try container.decode(URL.self, forKey: .imagePredictionUrl)
        let iso8601Duration = try container.decode(String.self, forKey: .timeout)
        timeout = iso8601Duration.timeIntervalFromISO8601Duration() ?? 7 // use a default of 7 seconds if this parsing fails
        impressionUrl = try? container.decode(URL.self, forKey: .impressionUrl)
        url = try container.decode(URL.self, forKey: .url)
        programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
        rewardsUrl = try? container.decode(URL.self, forKey: .rewardsUrl)
        customData = try? container.decode(String.self, forKey: .customData)
        claimUrl = try container.decode(URL.self, forKey: .claimUrl)
        imagePredictionId = try container.decode(String.self, forKey: .imagePredictionId)
    }
}

extension ImagePredictionFollowUp {
    var correctOptionsIds: [String] {
        return options
            .filter({$0.isCorrect})
            .map({ $0.id })
    }
}
