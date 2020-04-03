//
//  ImageSliderVote.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/16/19.
//

import Foundation

struct ImageSliderVote: Encodable {
    let magnitude: String
}

struct ImageSliderVoteResponse: Decodable {
    let id: String
}
