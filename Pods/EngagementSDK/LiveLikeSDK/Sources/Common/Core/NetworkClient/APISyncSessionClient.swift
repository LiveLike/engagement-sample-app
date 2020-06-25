//
//  NetworkClient.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-30.
//

import Foundation

protocol ApplicationConfigVendor {
    var whenApplicationConfig: Promise<ApplicationConfiguration> { get }
}

class ApplicationConfigClient: ApplicationConfigVendor {
    lazy var whenApplicationConfig: Promise<ApplicationConfiguration> =
        LiveLikeAPI.getApplicationConfiguration(apiBaseURL: self.apiBaseURL, clientID: self.clientID)

    private let apiBaseURL: URL
    private let clientID: String

    init(apiBaseURL: URL, clientID: String) {
        self.clientID = clientID
        self.apiBaseURL = apiBaseURL
    }
}

protocol UserAccessTokenGenerator {
    func generate() -> Promise<AccessToken>
}

class APIAccessTokenGenerator: UserAccessTokenGenerator {
    private let livelikeRestAPIService: LiveLikeRestAPIServicable

    init(livelikeRestAPIService: LiveLikeRestAPIServicable) {
        self.livelikeRestAPIService = livelikeRestAPIService
    }

    func generate() -> Promise<AccessToken> {
        return firstly {
            livelikeRestAPIService.whenApplicationConfig
        }.then { appConfig in
            LiveLikeAPI.requestAccessTokenResource(url: appConfig.profileUrl)
        }.then { accessTokenResource in
            Promise(value: AccessToken(fromString: accessTokenResource.accessToken))
        }
    }
}

struct LiveLikeAPI {
    static func getApplicationConfiguration(apiBaseURL: URL, clientID: String) -> Promise<ApplicationConfiguration> {
        let url = apiBaseURL.appendingPathComponent("applications").appendingPathComponent(clientID)
        let resource = Resource<ApplicationConfiguration>(get: url)
        return EngagementSDK.networking.load(resource)
    }

    struct AccessTokenResource: Decodable {
        let accessToken: String
    }

    static func requestAccessTokenResource(url: URL) -> Promise<AccessTokenResource> {
        let resource = Resource<AccessTokenResource>(url: url, method: .post(EmptyBody()))
        return EngagementSDK.networking.load(resource)
    }
}
