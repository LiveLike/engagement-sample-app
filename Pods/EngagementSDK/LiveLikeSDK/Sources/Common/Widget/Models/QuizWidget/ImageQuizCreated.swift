//
//  ImageQuizCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/25/19.
//

import Foundation

struct ImageQuizCreated: Decodable {
    let id: String
    let question: String
    let choices: [ImageQuizChoice]
    let timeout: Timeout
    let subscribeChannel: String
    let impressionUrl: URL?
    let programId: String
    let programDateTime: Date?
    let kind: WidgetKind
    let rewardsUrl: URL?
    var customData: String?
    let createdAt: Date
    let publishedAt: Date?
}

struct ImageQuizChoice: Decodable {
    let id: String
    let description: String
    let imageUrl: URL
    let isCorrect: Bool
    let answerCount: Int
    let answerUrl: URL
}
