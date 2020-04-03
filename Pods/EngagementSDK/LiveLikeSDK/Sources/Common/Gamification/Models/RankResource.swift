//
//  RankResource.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/15/19.
//

import Foundation

struct RankResource: Decodable {
    var points: Int
    var totalPoints: Int
    var rank: Int
    var currentBadge: APIRewardsClient.BadgeResource?
    var nextBadge: APIRewardsClient.BadgeResource?
    var previousBadge: APIRewardsClient.BadgeResource?
}
