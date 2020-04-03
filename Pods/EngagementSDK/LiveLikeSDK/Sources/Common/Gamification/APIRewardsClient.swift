//
//  APIRewardsClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/9/19.
//

import Foundation

class APIRewardsClient {
    private let accessToken: AccessToken

    init(accessToken: AccessToken) {
        self.accessToken = accessToken
    }

    func getRewards(at rewardsURL: URL) -> Promise<RewardsResource> {
        let resource = Resource<RewardsResource>(url: rewardsURL, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}

// MARK: - Models

extension APIRewardsClient {
    struct RewardsResource: Decodable {
        let points: Int
        let totalPoints: Int
        let rank: Int

        let newPoints: Int
        let newBadges: [BadgeResource]
        let currentBadge: BadgeResource?
        let nextBadge: BadgeResource?
        let previousBadge: BadgeResource?
    }

    struct BadgeResource: Decodable {
        let id: String
        let name: String
        let file: URL
        let mimetype: MIMEType
        let points: Int
        let level: Int
    }
}

typealias MIMEType = String

extension MIMEType {
    var isImage: Bool {
        return hasPrefix("image/")
    }
}
