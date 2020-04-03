//
//  RankClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/15/19.
//

import Foundation

class RankClient {
    private let rankURL: URL
    private let accessToken: AccessToken
    private let rewardsType: RewardsType
    private var awardsListeners: Listener<AwardsProfileDelegate> = Listener()

    init(rankURL: URL, accessToken: AccessToken, rewardsType: RewardsType) {
        self.rankURL = rankURL
        self.accessToken = accessToken
        self.rewardsType = rewardsType

        getUserRank()
    }
    
    func getUserRank() {
        guard rewardsType != .noRewards else { return }
        
        firstly {
            loadRankResource()
        }.then { rankResource in
            let awardsProfile = AwardsProfile(from: rankResource)
            self.awardsListeners.publish { $0.awardsProfile(didUpdate: awardsProfile) }
        }.catch { error in
            log.error("Failed to load rank resource with error: \(error)")
        }
    }

    private func loadRankResource() -> Promise<RankResource> {
        let resource = Resource<RankResource>(get: rankURL, accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}

extension RankClient: AwardsProfileVendor {
    func addDelegate(_ delegate: AwardsProfileDelegate) {
        awardsListeners.addListener(delegate)
    }

    func removeDelegate(_ delegate: AwardsProfileDelegate) {
        awardsListeners.removeListener(delegate)
    }
}
