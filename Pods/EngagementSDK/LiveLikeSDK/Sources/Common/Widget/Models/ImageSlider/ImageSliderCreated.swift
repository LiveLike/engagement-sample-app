//
//  ImageSliderCreated.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/13/19.
//

import Foundation

typealias StringDouble = String

extension StringDouble {
    var number: Double? {
        return Double(self)
    }
}

struct ImageSliderCreated: Decodable {
    var subscribeChannel: String
    var id: String
    var initialMagnitude: StringDouble
    var voteUrl: URL
    var impressionUrl: URL?
    var kind: WidgetKind
    var timeout: Timeout
    var question: String
    var url: URL
    var programDateTime: Date?
    var options: [ImageSliderOption]
    var rewardsUrl: URL?
}

struct ImageSliderOption: Decodable {
    var id: String
    var imageUrl: URL
}
