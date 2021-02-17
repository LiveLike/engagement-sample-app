//
//  ImageSliderResults.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import Foundation

struct ImageSliderResults: Decodable {
    let id: String
    // null when there are not votes
    var averageMagnitude: String?
}
