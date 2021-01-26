//
//  ImagePollResults.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/18/19.
//

import Foundation

struct PollResultsOption {
    let id: String
    var voteCount: Int

    init(id: String, voteCount: Int) {
        self.id = id
        self.voteCount = voteCount
    }
}

struct PollResults {
    let id: String
    var options: [PollResultsOption]
}

extension PollResultsOption: Decodable {}
extension PollResults: Decodable {}
