//
//  ImageQuizCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/25/19.
//

import Foundation

struct ImageQuizCreated: Decodable {
    var id: String
    var question: String
    var choices: [ImageQuizChoice]
    var timeout: Timeout
    var subscribeChannel: String
    var impressionUrl: URL?
    var programId: String
    var programDateTime: Date?
    var kind: WidgetKind
    var rewardsUrl: URL?

    let animationTimerAsset: String = "timer"
}

struct ImageQuizChoice: Decodable {
    var id: String
    var description: String
    var imageUrl: URL
    var isCorrect: Bool
    var answerCount: Int
    var answerUrl: URL
}
