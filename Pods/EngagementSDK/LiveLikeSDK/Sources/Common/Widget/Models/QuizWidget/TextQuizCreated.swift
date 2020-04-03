//
//  TextQuizCreated.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import Foundation

struct TextQuizCreated: Decodable {
    var id: String
    var question: String
    var choices: [TextQuizChoice]
    var timeout: Timeout
    var subscribeChannel: String
    var programId: String
    var programDateTime: Date?
    var kind: WidgetKind
    var impressionUrl: URL?
    var rewardsUrl: URL?

    let animationTimerAsset: String = "timer"
}

struct TextQuizChoice: Decodable {
    var id: String
    var description: String
    var isCorrect: Bool
    var answerCount: Int
    var answerUrl: URL
}
