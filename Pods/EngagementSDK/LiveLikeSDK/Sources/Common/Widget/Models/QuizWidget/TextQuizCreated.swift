//
//  TextQuizCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import Foundation

struct TextQuizCreated: Codable {
    let id: String
    let question: String
    let choices: [TextQuizChoice]
    let timeout: Timeout
    let subscribeChannel: String
    let programId: String
    let programDateTime: Date?
    let kind: WidgetKind
    let impressionUrl: URL?
    let rewardsUrl: URL?
    var customData: String?
    let createdAt: Date
    let publishedAt: Date?
}

struct TextQuizChoice: Codable {
    let id: String
    let description: String
    let isCorrect: Bool
    let answerCount: Int
    let answerUrl: URL
}
