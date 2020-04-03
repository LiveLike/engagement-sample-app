//
//  QuizVote.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/22/19.
//

import Foundation

struct QuizVote: Decodable {
    var id: String
    var url: URL
    var choiceId: String
    var isCorrect: Bool
}
