//
//  EngagementSDK+AccessToken.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/12/19.
//

import Foundation

/// A protocol for managing storage of the user's access token.
@objc public protocol AccessTokenStorage {
    /// This method is called as part of EngagementSDK setup to check for a stored access token between sessions.
    func fetchAccessToken() -> String?
    /// This method is called when a new access token is generated. This method should store the token where it can be retreived in future sessions via the `fetchAccessToken()` method.
    func storeAccessToken(accessToken: String)
}

class UserDefaultsAccessTokenStorage: AccessTokenStorage {
    let defaultKey = "com.livelike.EngagementSDK:LiveLikeAccessToken"
    func fetchAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: defaultKey)
    }
    func storeAccessToken(accessToken: String) {
        UserDefaults.standard.set(accessToken, forKey: defaultKey)
    }
}
