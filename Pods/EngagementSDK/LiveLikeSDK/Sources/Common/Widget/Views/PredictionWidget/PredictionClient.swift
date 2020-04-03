//
//  PredictionClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/12/19.
//

import Foundation

protocol PredictionVoteClient {
    func vote(url: URL) -> Promise<WidgetVote>
}

class PredictionClient: PredictionVoteClient {
    private let accessToken: AccessToken

    init(accessToken: AccessToken) {
        self.accessToken = accessToken
    }

    func vote(url: URL) -> Promise<WidgetVote> {
        let resource = Resource<WidgetVote>(url: url, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}
