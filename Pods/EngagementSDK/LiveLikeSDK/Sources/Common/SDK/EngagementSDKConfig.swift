//
//  EngagementSDKConfig.swift
//  EngagementSDK
//
//  Created by Jelzon WORK on 3/19/20.
//

import Foundation

/// Configuration for initializing an instance of the EngagementSDK
public struct EngagementSDKConfig {
    
    static var defaultAPIOrigin: URL = URL(string: "https://cf-blast.livelikecdn.com/api/v1")!
    
    /// The unique id given by LiveLike
    public let clientID: String
    
    /// Set this to route LiveLike API requests to a different origin
    public var apiOrigin: URL = EngagementSDKConfig.defaultAPIOrigin
    
    /// Set this to customize how you want the user's access token to be stored.
    /// By default the user's access token will be stored in UserDefaults.standard
    public var accessTokenStorage: AccessTokenStorage = UserDefaultsAccessTokenStorage()
    
    /// Should the EngagementSDK initialize Bugsnag for crash reporting.
    /// You should set this property to `false` if you integrate Bugsnag for your application.
    /// By default this property is `true`.
    public var isBugsnagEnabled: Bool = true
    
    public init(clientID: String) {
        self.clientID = clientID
    }
}
