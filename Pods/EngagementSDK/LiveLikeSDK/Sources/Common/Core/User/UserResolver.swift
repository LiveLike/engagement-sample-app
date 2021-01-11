//
//  UserSessionRestorer.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-14.
//

import Foundation

/// A `UserResolver` fetchs a `UserSession` from either the local storage
/// or livelike backend.
///
/// A `UserSession` is valid for the life of the application
/// Once a `UserSession` is created from livelike CMS, that value is
/// persisted across application launches. Before sending a request to
/// livelike backend we check the local persistent store and use that value.
class UserResolver: LiveLikeIDVendor, UserNicknameService, AccessTokenVendor, UserProfileVendor {
    // MARK: - Internal Properties

    lazy var whenLiveLikeID: Promise<LiveLikeID> = {
        firstly {
            self.whenProfileResource
        }.then { profileResource in
            LiveLikeID(from: profileResource.id)
        }
    }()

    lazy var whenInitialNickname: Promise<String> = {
        firstly {
            self.whenProfileResource
        }.then { [weak self] profileResource -> String in
            let nickname = profileResource.nickname
            self?.currentNickname = nickname
            return nickname
        }
    }()

    var nicknameDidChange: [(String) -> Void] = []
    private(set) var currentNickname: String? {
        didSet {
            guard let currentNickname = currentNickname else { return }
            nicknameDidChange.forEach { $0(currentNickname) }
        }
    }

    func setNickname(nickname: String) -> Promise<String> {
        return firstly {
            Promises.zip(whenAccessToken, livelikeAPI.whenApplicationConfig)
        }.then { accessToken, appResource in
            self.livelikeAPI.setNickname(profileURL: appResource.profileUrl, nickname: nickname, accessToken: accessToken)
        }.then(on: DispatchQueue.global()) { profile -> String in
            let newNickname = profile.nickname
            self.currentNickname = nickname
            return newNickname
        }
    }

    lazy var whenAccessToken: Promise<AccessToken> = {
        if let accessTokenString = self.accessTokenStorage.fetchAccessToken() {
            return validateAccessToken(AccessToken(fromString: accessTokenString))
        } else {
            return generateNewAccessToken()
        }
    }()
    
    private func generateNewAccessToken() -> Promise<AccessToken> {
        return firstly {
            livelikeAPI.whenApplicationConfig
        }.then {
            log.warning("""
            The EngagementSDK is creating a new User Profile because it was initialized without an existing Access Token.
            The created User Profile will be counted towards the Monthly Active Users (MAU) calculation.
            For more information: https://docs.livelike.com/docs/user-profiles
            """)
            return self.livelikeAPI.createProfile(profileURL: $0.profileUrl)
        }.ensure { [weak self] in
            self?.accessTokenStorage.storeAccessToken(accessToken: $0.asString)
            return true
        }
    }
    
    lazy var whenProfileResource: Promise<ProfileResource> = {
        return firstly {
            Promises.zip(whenAccessToken, livelikeAPI.whenApplicationConfig)
        }.then { accessToken, appResource in
            return self.livelikeAPI.getProfile(profileURL: appResource.profileUrl, accessToken: accessToken)
        }
    }()

    // MARK: Private Properties

    private let accessTokenStorage: AccessTokenStorage
    private let livelikeAPI: LiveLikeRestAPIServicable
    private weak var sdkDelegate: InternalErrorReporter?

    /**
     - Parameter integratorAccessToken: The access token given by the integrator to attempt to retreive a user's profile
     */
    init(accessTokenStorage: AccessTokenStorage,
         livelikeAPI: LiveLikeRestAPIServicable,
         sdkDelegate: InternalErrorReporter)
    {
        self.accessTokenStorage = accessTokenStorage
        self.livelikeAPI = livelikeAPI
        self.sdkDelegate = sdkDelegate
    }

    /**
     Test access token is valid by requesting the profile
     If token is invalid (403 Invalid Authorization) returns anonymous profile
     */
    private func validateAccessToken(_ accessToken: AccessToken) -> Promise<AccessToken> {
        return firstly {
            self.livelikeAPI.whenApplicationConfig
        }.then {
            self.livelikeAPI.getProfile(profileURL: $0.profileUrl, accessToken: accessToken)
        }.then { _ in
            // successfully loaded profile - access token is good
            Promise(value: accessToken)
        }.recover { (error) -> Promise<AccessToken> in
            switch error {
            case NetworkClientError.forbidden,
                 NetworkClientError.unauthorized:
                self.sdkDelegate?.report(setupError: .invalidUserAccessToken(accessToken.asString))
            default:
                self.sdkDelegate?.report(setupError: .unknownError(error))
            }
            return self.generateNewAccessToken()
        }
    }
}

// MARK: - Network Request

/// Represents a user's profile
public struct ProfileResource: Decodable {
    public let id: String
    public let nickname: String
    public let chatRoomMembershipsUrl: URL
}

protocol UserProfileVendor {
    var whenProfileResource: Promise<ProfileResource> { get }
}

protocol AccessTokenVendor {
    var whenAccessToken: Promise<AccessToken> { get }
}

protocol LiveLikeIDVendor {
    var whenLiveLikeID: Promise<LiveLikeID> { get }
}

protocol UserNicknameVendor: AnyObject {
    var whenInitialNickname: Promise<String> { get }
    var currentNickname: String? { get }
    var nicknameDidChange: [(String) -> Void] { get set }
}

protocol UserNicknameService: UserNicknameVendor {
    func setNickname(nickname: String) -> Promise<String>
}

struct AccessToken {
    private let internalToken: String

    init(fromString token: String) {
        internalToken = token
    }

    var asString: String {
        return internalToken
    }
}

struct LiveLikeID {
    private let internalID: String

    init(from string: String) {
        internalID = string
    }

    var asString: String {
        return internalID
    }
}
