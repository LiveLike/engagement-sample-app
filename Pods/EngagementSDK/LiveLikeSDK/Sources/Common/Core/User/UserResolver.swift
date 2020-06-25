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
class UserResolver: LiveLikeIDVendor, UserNicknameService, UserPointsVendor, AccessTokenVendor, UserProfileVendor {
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
        let userProfileService = self.userProfileService

        return firstly {
            whenAccessToken
        }.then {
            userProfileService.setNickname(nickname, forAccessToken: $0)
        }.then(on: DispatchQueue.global()) { profile -> String in
            let newNickname = profile.nickname
            self.currentNickname = nickname
            return newNickname
        }
    }
    
    lazy var whenUserPoints: Promise<Int> = {
        firstly {
            self.whenProfileResource
        }.then { profileResource in
            profileResource.points
        }
    }()

    lazy var whenAccessToken: Promise<AccessToken> = {
        if let accessTokenString = self.accessTokenStorage.fetchAccessToken() {
            return validateAccessToken(AccessToken(fromString: accessTokenString))
        } else {
            return generateNewAccessToken()
        }
    }()
    
    private func generateNewAccessToken() -> Promise<AccessToken> {
        return firstly {
            accessTokenGenerator.generate()
        }.ensure { [weak self] in
            self?.accessTokenStorage.storeAccessToken(accessToken: $0.asString)
            return true
        }
    }
    
    lazy var whenProfileResource: Promise<ProfileResource> = {
        let userProfileService = self.userProfileService
        return firstly {
            whenAccessToken
        }.then { accessToken in
            return userProfileService.getProfile(forAccessToken: accessToken)
        }.then { [weak self] profileResource in
            let awardsProfile = AwardsProfile(from: profileResource)
            self?.awardsListeners.publish { $0.awardsProfile(didUpdate: awardsProfile) }
            return Promise(value: profileResource)
        }
    }()

    // MARK: Private Properties

    private let accessTokenStorage: AccessTokenStorage
    private let userProfileService: UserProfileService
    private let accessTokenGenerator: UserAccessTokenGenerator
    private weak var sdkDelegate: InternalErrorReporter?
    private var awardsListeners: Listener<AwardsProfileDelegate> = Listener()

    /**
     - Parameter integratorAccessToken: The access token given by the integrator to attempt to retreive a user's profile
     */
    init(accessTokenStorage: AccessTokenStorage,
         userProfileService: UserProfileService,
         accessTokenGenerator: UserAccessTokenGenerator,
         sdkDelegate: InternalErrorReporter)
    {
        self.accessTokenStorage = accessTokenStorage
        self.userProfileService = userProfileService
        self.accessTokenGenerator = accessTokenGenerator
        self.sdkDelegate = sdkDelegate
    }

    /**
     Test access token is valid by requesting the profile
     If token is invalid (403 Invalid Authorization) returns anonymous profile
     */
    private func validateAccessToken(_ accessToken: AccessToken) -> Promise<AccessToken> {
        return firstly {
            self.userProfileService.getProfile(forAccessToken: accessToken)
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

extension UserResolver: AwardsProfileVendor {
    func addDelegate(_ delegate: AwardsProfileDelegate) {
        awardsListeners.addListener(delegate)
    }

    func removeDelegate(_ delegate: AwardsProfileDelegate) {
        awardsListeners.removeListener(delegate)
    }
}

// MARK: - Network Request

/// Represents a user's profile
public struct ProfileResource: Decodable {
    public let id: String
    public let nickname: String
    public let chatRoomMembershipsUrl: URL
    
    // Gamification Properties
    let points: Int
    let badges: [APIRewardsClient.BadgeResource]
    let currentBadge: APIRewardsClient.BadgeResource?
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

protocol UserPointsVendor {
    var whenUserPoints: Promise<Int> { get }
}

protocol UserProfileService {
    func setNickname(_ nickname: String, forAccessToken accessToken: AccessToken) -> Promise<ProfileResource>
    func getProfile(forAccessToken accessToken: AccessToken) -> Promise<ProfileResource>
}

class APIUserProfileService: UserProfileService {
    private let livelikeRestAPIService: LiveLikeRestAPIServicable

    init(livelikeRestAPIService: LiveLikeRestAPIServicable) {
        self.livelikeRestAPIService = livelikeRestAPIService
    }

    func getProfile(forAccessToken accessToken: AccessToken) -> Promise<ProfileResource> {
        return firstly {
            self.livelikeRestAPIService.whenApplicationConfig
        }.then { appConfig in
            self.requestProfileResource(url: appConfig.profileUrl, accessToken: accessToken.asString)
        }
    }

    func setNickname(_ nickname: String, forAccessToken accessToken: AccessToken) -> Promise<ProfileResource> {
        //swiftlint:disable nesting
        struct NicknamePatchBody: Encodable {
            let nickname: String
        }
        //swiftlint:enable nesting

        return firstly {
            self.livelikeRestAPIService.whenApplicationConfig
        }.then { appConfig in
            let body = NicknamePatchBody(nickname: nickname)
            let resource = Resource<ProfileResource>(url: appConfig.profileUrl,
                                                     method: .patch(body),
                                                     accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }
    }

    private func requestProfileResource(url: URL, accessToken: String) -> Promise<ProfileResource> {
        let resource = Resource<ProfileResource>(get: url, accessToken: accessToken)
        return EngagementSDK.networking.load(resource)
    }
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
