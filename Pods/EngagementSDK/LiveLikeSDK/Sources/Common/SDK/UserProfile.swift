//
//  UserProfile.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/2/20.
//

import Foundation

/// Methods for managing changes to a User's profile.
protocol UserProfileDelegate: AnyObject {
    /// Tells the delegate that the User has earned rewards
    func userProfile(_ userProfile: UserProfile, didEarnRewards rewards: [Reward])
}

protocol UserProfileProtocol {
    var userID: LiveLikeID { get }
    var accessToken: AccessToken { get }
    func notifyRewardItemsEarned(rewards: [Reward])
}

/// Methods for managing a User's profile.
class UserProfile: UserProfileProtocol {

    weak var delegate: UserProfileDelegate?

    let userID: LiveLikeID
    let accessToken: AccessToken

    init(userID: LiveLikeID, accessToken: AccessToken) {
        self.userID = userID
        self.accessToken = accessToken
    }

    func notifyRewardItemsEarned(
        rewards: [Reward]
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.userProfile(self, didEarnRewards: rewards)
        }
    }
}
