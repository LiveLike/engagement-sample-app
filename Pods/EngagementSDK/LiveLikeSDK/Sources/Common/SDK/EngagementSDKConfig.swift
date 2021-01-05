//
//  EngagementSDKConfig.swift
//  EngagementSDK
//
//  Created by Jelzon WORK on 3/19/20.
//

import Foundation

/// Configuration for initializing an instance of the EngagementSDK
public struct EngagementSDKConfig {
    
    /// Configuration options related to Widgets
    public struct Widget {
        /// Override this to manage how and where the user's prediction votes are persisted.
        /// By default the user's prediction votes are kept in user domain file storage
        public var predictionVoteRepository: PredictionVoteRepository = WidgetVotes()
        
        internal init() {}
    }
    
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
    /// By default this property is `true`
    @available(*, deprecated, message: "EngagementSDK is no longer using Bugsnag, please remove the reference to `isBugsnagEnabled` in your code")
    public var isBugsnagEnabled: Bool = true
    
    /// Configuration options related to Widgets
    public var widget: Widget = Widget()
    
    public init(clientID: String) {
        self.clientID = clientID
    }
}
