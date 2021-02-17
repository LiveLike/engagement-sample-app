//
//  ViewController.swift
//  Test
//
//  Created by Cory Sullivan on 2019-01-11.
//  Copyright © 2019 Cory Sullivan. All rights reserved.
//

import UIKit
/**
  The entry point for all interaction with the EngagementSDK.

 - Important: Concurrent instances of the EngagementSDK is not supported; Only one instance should exist at any time.
 */
public class EngagementSDK: NSObject {
    // MARK: - Static Properties

    // MARK: Internal

    static let networking: SDKNetworking = SDKNetworking(sdkVersion: EngagementSDK.version)
    static let prodAPIEndpoint: URL = URL(string: "https://cf-blast.livelikecdn.com/api/v1")!
    static let mediaRepository: MediaRepository = MediaRepository(cache: Cache.shared)

    // MARK: - Stored Properties

    // MARK: Public

    /// The sdk's delegate, currently only used to report setup errors
    public weak var delegate: EngagementSDKDelegate?
    
    private let config: EngagementSDKConfig
    
    /// The EngagementSDKConfig used to initialize this instance of the EngagementSDK
    public var currentConfiguration: EngagementSDKConfig {
        return config
    }

    // MARK: Internal

    private var clientID: String {
        config.clientID
    }
    private(set) var whenInitializedAndReady: Promise<Void> = Promise()

    var widgetPauseStatus: PauseStatus {
        didSet {
            UserDefaults.standard.set(areWidgetsPausedForAllSessions, forKey: EngagementSDK.permanentPauseUserDefaultsKey)
            widgetPauseDelegates.publish { $0.pauseStatusDidChange(status: self.widgetPauseStatus) }
        }
    }

    // MARK: Private
    
    private var whenMessagingClients: Promise<InternalContentSession.MessagingClients>!
    private var livelikeRestAPIService: LiveLikeRestAPIServicable
    private var whenProgramURLTemplate: Promise<String>
    private let accessTokenVendor: AccessTokenVendor
    private let livelikeIDVendor: LiveLikeIDVendor
    private let userNicknameService: UserNicknameService
    private let userProfileVendor: UserProfileVendor
    private let sdkErrorReporter: InternalErrorReporter
    private let predictionVoteRepo: PredictionVoteRepository
    private let leaderboardsManager: LeaderboardsManager = LeaderboardsManager()

    private let widgetPauseDelegates: Listener<PauseDelegate> = Listener<PauseDelegate>()
    private let analytics: Analytics

    private lazy var orientationAnalytics = OrientationChangeAnalytics(eventRecorder: self.eventRecorder,
                                                                       superPropertyRecorder: self.superPropertyRecorder,
                                                                       peoplePropertyRecorder: self.peoplePropertyRecorder)
    struct PaginationProgress {
        var next: URL?
        var previous: URL?
        var total: Int = 0
    }
    var chatRoomMembershipPagination: PaginationProgress
    var userChatRoomMembershipPagination: PaginationProgress
    var leaderboardEntriesPagination: PaginationProgress
    private let leaderboardEnriesPromiseQueue = PromiseQueue(name: "com.livelike.leaderboardEntries",
                                                             maxConcurrentPromises: 1)
    
    private(set) lazy var whenUserProfile: Promise<UserProfile> = {
        return firstly {
            Promises.zip(self.accessTokenVendor.whenAccessToken, self.livelikeIDVendor.whenLiveLikeID)
        }.then { accessToken, livelikeID in
            return UserProfile(userID: livelikeID, accessToken: accessToken)
        }
    }()

    private lazy var whenWidgetModelFactory: Promise<WidgetModelFactory> = {
        return firstly {
            Promises.zip(
                self.whenMessagingClients,
                self.accessTokenVendor.whenAccessToken,
                self.whenUserProfile
            )
        }.then { messagingClient, accessToken, userProfile in
            guard let widgetClient = messagingClient.widgetMessagingClient else { return Promise(error: ContentSessionError.missingWidgetClient) }
            let widgetModelFactory = WidgetModelFactory(
                eventRecorder: self.eventRecorder,
                userProfile: userProfile,
                rewardItems: [],
                leaderboardsManager: self.leaderboardsManager,
                accessToken: accessToken,
                widgetClient: widgetClient,
                livelikeRestAPIService: self.livelikeRestAPIService,
                predictionVoteRepo: self.predictionVoteRepo
            )
            return Promise(value: widgetModelFactory)
        }
    }()

    // MARK: - Initialization
    
    /// Initializes an instance of the EngagementSDK
    /// - Parameter config: An EngagementSDKConfig object
    public convenience init(config: EngagementSDKConfig) {
        let livelikeRestAPIService = LiveLikeRestAPIServices(apiBaseURL: config.apiOrigin, clientID: config.clientID)
        let sdkErrorReporter = InternalErrorReporter()
        let userResolver = UserResolver(accessTokenStorage: config.accessTokenStorage,
                                        livelikeAPI: livelikeRestAPIService,
                                        sdkDelegate: sdkErrorReporter)

        self.init(
            config: config,
            livelikeRestAPIService: livelikeRestAPIService,
            accessTokenVendor: userResolver,
            livelikeIDVendor: userResolver,
            userNicknameService: userResolver,
            userProfileVendor: userResolver,
            sdkErrorReporter: sdkErrorReporter
        )
    }

    internal init(
        config: EngagementSDKConfig,
        livelikeRestAPIService: LiveLikeRestAPIServicable,
        accessTokenVendor: AccessTokenVendor,
        livelikeIDVendor: LiveLikeIDVendor,
        userNicknameService: UserNicknameService,
        userProfileVendor: UserProfileVendor,
        sdkErrorReporter: InternalErrorReporter
    ) {
        self.config = config
        self.predictionVoteRepo = config.widget.predictionVoteRepository
        self.accessTokenVendor = accessTokenVendor
        self.livelikeRestAPIService = livelikeRestAPIService
        self.livelikeIDVendor = livelikeIDVendor
        self.userNicknameService = userNicknameService
        self.userProfileVendor = userProfileVendor
        self.sdkErrorReporter = sdkErrorReporter
        analytics = Analytics(livelikeRestAPIService: livelikeRestAPIService)
        whenProgramURLTemplate = Promise<String>()
        log.info("Initializing EngagementSDK using client id: '\(config.clientID)'")
        widgetPauseStatus = UserDefaults.standard.bool(forKey: EngagementSDK.permanentPauseUserDefaultsKey) == true ? .paused : .unpaused
        self.chatRoomMembershipPagination = PaginationProgress()
        self.userChatRoomMembershipPagination = PaginationProgress()
        self.leaderboardEntriesPagination = PaginationProgress()

        super.init()
        sdkErrorReporter.delegate = self
        whenMessagingClients = messagingClientPromise()

        whenMessagingClients.catch { [weak self] error in
            guard let self = self else { return }

            let delegateError: Error
            let logger: (String) -> Void
            switch error {
            case NetworkClientError.badRequest:
                delegateError = SetupError.invalidClientID(config.clientID)
                logger = log.severe(_:)

            case NetworkClientError.internalServerError:
                delegateError = SetupError.internalServerError
                logger = log.severe(_:)

            default:
                delegateError = SetupError.unknownError(error)
                logger = log.debug(_:)
            }

            self.delegate?.sdk?(self, setupFailedWithError: delegateError)
            logger(error.localizedDescription)

            return self.whenMessagingClients.reject(URLError(.badURL))
        }
        
        /// 1. Load application resource
        /// 2. Load profile resource
        firstly {
            Promises.zip(
                self.livelikeRestAPIService.whenApplicationConfig,
                self.userNicknameService.whenInitialNickname,
                self.livelikeIDVendor.whenLiveLikeID
            )
        }.then { _, _, _ in
            self.delegate?.sdk?(setupCompleted: self)
        }.catch { error in
            switch error {
            case NetworkClientError.badRequest, NetworkClientError.notFound404:
                if config.apiOrigin != EngagementSDKConfig.defaultAPIOrigin {
                    self.delegate?.sdk?(self, setupFailedWithError: SetupError.invalidAPIOrigin)
                } else {
                    self.delegate?.sdk?(self, setupFailedWithError: SetupError.invalidClientID(config.clientID))
                }
            default:
                self.delegate?.sdk?(self, setupFailedWithError: error)
            }
        }
    }

    struct LeaderboardAndCurrentEntry {
        let leaderboard: LeaderboardResource
        let currentEntry: LeaderboardEntryResource?
    }

    func getLeaderboardAndCurrentEntry(leaderboardID: String, profileID: String) -> Promise<LeaderboardAndCurrentEntry> {
        firstly {
            self.livelikeRestAPIService.getLeaderboard(leaderboardID: leaderboardID)
        }.then { leaderboard in
            return self.getLeaderboardAndCurrentEntry(leaderboard: leaderboard, profileID: profileID)
        }
    }

    func getLeaderboardAndCurrentEntry(leaderboard: LeaderboardResource, profileID: String) -> Promise<LeaderboardAndCurrentEntry> {
        firstly {
            self.accessTokenVendor.whenAccessToken
        }.then { accessToken -> Promise<LeaderboardEntryResource> in
            guard let entryURL = leaderboard.getEntryURL(profileID: profileID) else {
                return Promise(error: LLGamificationError.leaderboardUrlCreationFailure)
            }
            return self.livelikeRestAPIService.getLeaderboardEntry(url: entryURL, accessToken: accessToken)
        }.then { leaderboardEntry in
            let leaderboardAndCurrentEntry = LeaderboardAndCurrentEntry(
                leaderboard: leaderboard,
                currentEntry: leaderboardEntry
            )
            return Promise(value: leaderboardAndCurrentEntry)
        }.recover { error in
            // If the user's entry is not found then recover with nil
            // A user will not have an entry until they earn their first points
            if case NetworkClientError.notFound404 = error {
                return Promise(value: LeaderboardAndCurrentEntry(
                    leaderboard: leaderboard,
                    currentEntry: nil)
                )
            } else {
                return Promise(error: error)
            }
        }
    }
    
    /// Gets the current user's profile
    func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        firstly {
            whenUserProfile
        }.then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    func createWidget(withJSONObject jsonObject: Any, completion: @escaping (Result<Widget, Error>) -> Void) {
        firstly {
            whenWidgetModelFactory
        }.then { widgetModelFactory in
            let widgetResource = try WidgetPayloadParser.parse(jsonObject)
            let widgetModel = try widgetModelFactory.make(from: widgetResource)
            guard let widget = DefaultWidgetFactory.makeWidget(from: widgetModel) else {
                throw GetWidgetError.widgetDoesNotExist
            }
            completion(.success(widget))
        }.catch {
            completion(.failure($0))
        }
    }

}

// MARK: - Static Public APIs

public extension EngagementSDK {
    /// A property to control the level of logging from the `EngagementSDK`.
    
    static var logLevel: LogLevel {
        get { return Logger.LoggingLevel }
        set { Logger.LoggingLevel = newValue }
    }
}

// MARK: - Public APIs

public extension EngagementSDK {
    /// A delegate that returns analytics events.
    var analyticsDelegate: EngagementAnalyticsDelegate? {
        get { return analytics.delegate }
        set { analytics.delegate = newValue }
    }

    /// Returns whether widgets are paused for all sessions
    var areWidgetsPausedForAllSessions: Bool {
        return widgetPauseStatus == .paused
    }

    /**
     Creates a new `ContentSession` instance using a SessionConfiguration object.

     - Parameter config: A configuration object that defines the properties for a `ContentSession`
     - Parameter delegate: an object that will act as the delegate of the content session.
     - Returns: returns the `ContentSession`
     */
    func contentSession(config: SessionConfiguration, delegate: ContentSessionDelegate) -> ContentSession {
        return contentSessionInternal(config: config, delegate: delegate)
    }

    /**
     Creates a new `ContentSession` instance using a SessionConfiguration object.

     - Parameter config: A configuration object that defines the properties for a `ContentSession`
     - Returns: returns the `ContentSession`
     */
    func contentSession(config: SessionConfiguration) -> ContentSession {
        return contentSessionInternal(config: config, delegate: nil)
    }
    
    // MARK: Chat
    
    /// Sets a user's display name and calls the completion block
    func setUserDisplayName(_ newDisplayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (1...20).contains(newDisplayName.count) else {
            completion(.failure(SetUserDisplayNameError.invalidNameLength))
            return
        }
        
        firstly {
            userNicknameService.setNickname(nickname: newDisplayName)
        }.then { _ in
            completion(.success(()))
        }.catch {
            completion(.failure($0))
        }
    }

    /**
     Sets a user's display name and calls the completion block
     - Note: This version of the method is for Objective-C, if using swift we encourage the variant which returns a `Result<Void, Error>`.
     */
    
    func setUserDisplayName(_ newDisplayName: String, completion: @escaping (Bool, Error?) -> Void) {
        setUserDisplayName(newDisplayName) {
            switch $0 {
            case .success:
                completion(true, nil)
            case let .failure(error):
                completion(false, error)
            }
        }
    }

    func getUserDisplayName(completion: @escaping (Result<String, Error>) -> Void) {
        firstly {
            userNicknameService.whenInitialNickname
        }.then { _ in
            guard let currentNickname = self.userNicknameService.currentNickname else {
                completion(.failure(NilError()))
                return
            }
            completion(.success(currentNickname))
        }.catch {
            completion(.failure($0))
        }
    }
    
    /// Creates a connection to a chat room.
    func connectChatRoom(
        config: ChatSessionConfig,
        completion: @escaping (Result<ChatSession, Error>) -> Void
    ) {
        log.info("Connecting to chat room with id \(config.roomID).")
        self.loadChatRoom(
            config: config
        ) { result in
            switch result {
            case .success(let chatRoom):
                let chatSession: InternalChatSessionProtocol = {
                    if let syncTimeSource = config.syncTimeSource {
                        log.info("Found syncTimeSource - Enabling Spoiler Free Sync for Chat Session with id \(config.roomID)")
                        let spoilerFreeChatRoom = SpoilerFreeChatSession(
                            realChatRoom: chatRoom,
                            playerTimeSource: syncTimeSource
                        )
                        return spoilerFreeChatRoom
                    } else {
                        return chatRoom
                    }
                }()
                
                log.info("Loading initial history for Chat Room with id: \(config.roomID)")
                chatSession.loadInitialHistory {
                    switch $0 {
                    case .success:
                        completion(.success(chatSession))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Creates a public chat room with an optional title
    func createChatRoom(title: String?, completion: @escaping (Result<String, Error>) -> Void) {
        createChatRoom(title: title, visibility: .everyone, completion: completion)
    }
    
    /// Creates a chat room with an optional title and an ability to set the room's visibility
    func createChatRoom(
        title: String?,
        visibility: ChatRoomVisibilty,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        firstly {
            Promises.zip(self.accessTokenVendor.whenAccessToken,
                         self.livelikeRestAPIService.whenApplicationConfig)
        }.then { accessToken, appConfig -> Promise<ChatRoomResource> in
            self.livelikeRestAPIService.createChatRoomResource(
                title: title,
                visibility: visibility,
                accessToken: accessToken,
                appConfig: appConfig
            )
        }.then { chatRoomResource in
            completion(.success(chatRoomResource.id))
        }.catch { error in
            log.error("Error creating room: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Retrieve information about a chat room
    func getChatRoomInfo(roomID: String, completion: @escaping (Result<ChatRoomInfo, Error>) -> Void) {
        firstly {
            self.accessTokenVendor.whenAccessToken
        }.then { accessToken -> Promise<ChatRoomResource> in
            self.livelikeRestAPIService.getChatRoomResource(roomID: roomID, accessToken: accessToken)
        }.then { chatRoomResource in
            completion(.success(ChatRoomInfo(id: chatRoomResource.id, title: chatRoomResource.title, visibility: chatRoomResource.visibility)))
        }.catch { error in
            log.error("Error getting chat room info: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Retrieve all the users who are members of a chat room
    func getChatRoomMemberships(roomID: String,
                                page: ChatRoomMembershipPagination,
                                completion: @escaping (Result<[ChatRoomMember], Error>) -> Void) {
        firstly {
            self.accessTokenVendor.whenAccessToken
        }.then { accessToken in
            return Promises.zip(
                Promise(value: accessToken),
                self.livelikeRestAPIService.getChatRoomResource(roomID: roomID, accessToken: accessToken)
            )
        }.then { accessToken, chatRoomResource -> Promise<ChatRoomMembershipsResult> in
            
            // Handle `.next`, `.previous` cases and their availibility
            var notFirstMembershipUrl: URL?
            switch page {
            case .first:
                // reset next/prev urls stored from previous calls to a different room
                self.chatRoomMembershipPagination = PaginationProgress()
            case .next:
                guard let nextPageUrl = self.chatRoomMembershipPagination.next  else {
                    log.info("Next chat room membership page is unavailable")
                    return Promise(value: ChatRoomMembershipsResult(members: [], next: nil, previous: nil))
                }
                notFirstMembershipUrl = nextPageUrl
            case .previous:
                guard let previousPageUrl = self.chatRoomMembershipPagination.previous  else {
                    log.info("Previous chat room membership page is unavailable")
                    return Promise(value: ChatRoomMembershipsResult(members: [], next: nil, previous: nil))
                }
                notFirstMembershipUrl = previousPageUrl
            }
            
            return self.livelikeRestAPIService.getChatRoomMemberships(url: notFirstMembershipUrl ?? chatRoomResource.membershipsUrl,
                                                               accessToken: accessToken)
        }.then { response in
            self.chatRoomMembershipPagination.next = response.next
            self.chatRoomMembershipPagination.previous = response.previous
            completion(.success(response.members))
        }.catch { error in
            log.error("Error getting room memberships: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Retrieve all Chat Rooms the current user is a member of
    func getUserChatRoomMemberships(page: ChatRoomMembershipPagination,
                                    completion: @escaping (Result<[ChatRoomInfo], Error>) -> Void) {
        firstly {
            Promises.zip(self.accessTokenVendor.whenAccessToken,
                         self.userProfileVendor.whenProfileResource)
        }.then { accessToken, profileResource -> Promise<UserChatRoomMembershipsResult> in
            
            // Handle `.next`, `.previous` cases and their availibility
            var notFirstMembershipUrl: URL?
            switch page {
            case .first:
                // reset next/prev urls stored from previous calls to a different room
                self.userChatRoomMembershipPagination = PaginationProgress()
            case .next:
                guard let nextPageUrl = self.userChatRoomMembershipPagination.next  else {
                    log.info("Next chat room membership page is unavailable")
                    return Promise(value: UserChatRoomMembershipsResult(chatRooms: [], next: nil, previous: nil))
                }
                notFirstMembershipUrl = nextPageUrl
            case .previous:
                guard let previousPageUrl = self.userChatRoomMembershipPagination.previous  else {
                    log.info("Previous chat room membership page is unavailable")
                    return Promise(value: UserChatRoomMembershipsResult(chatRooms: [], next: nil, previous: nil))
                }
                notFirstMembershipUrl = previousPageUrl
            }
            
            return self.livelikeRestAPIService.getUserChatRoomMemberships(url: notFirstMembershipUrl ?? profileResource.chatRoomMembershipsUrl,
                                                                          accessToken: accessToken,
                                                                          page: page)
        }.then { userChatRoomMembershipsResult in
            self.userChatRoomMembershipPagination.next = userChatRoomMembershipsResult.next
            self.userChatRoomMembershipPagination.previous = userChatRoomMembershipsResult.previous
            completion(.success(userChatRoomMembershipsResult.chatRooms))
        }.catch { error in
            log.error("Error getting user chat room memberships: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Create a membership between the current user and a Chat Room
    func createUserChatRoomMembership(roomID: String,
                                      completion: @escaping (Result<ChatRoomMember, Error>) -> Void) {
        firstly {
           self.accessTokenVendor.whenAccessToken
        }.then { accessToken -> Promise<ChatRoomMember> in
            self.livelikeRestAPIService.createChatRoomMembership(roomID: roomID, accessToken: accessToken)
        }.then { chatRoomMember in
             completion(.success(chatRoomMember))
        }.catch { error in
            log.error("Error creating room membership: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Deletes a membership between the current user and a Chat Room
    func deleteUserChatRoomMembership(roomID: String,
                                      completion: @escaping (Result<Bool, Error>) -> Void) {
        firstly {
           self.accessTokenVendor.whenAccessToken
        }.then { accessToken -> Promise<Bool> in
            self.livelikeRestAPIService.deleteChatRoomMembership(roomID: roomID, accessToken: accessToken)
        }.then { chatRoomMember in
             completion(.success(chatRoomMember))
        }.catch { error in
            log.error("Error deleting room membership: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Find out whether the current user is muted for a `roomID`
    func getChatUserMutedStatus(roomID: String,
                                completion: @escaping (Result<ChatUserMuteStatus, Error>) -> Void) {
        firstly {
            self.whenUserProfile
        }.then { userProfile -> Promise<ChatUserMuteStatusResource> in
            self.livelikeRestAPIService.getChatUserMutedStatus(profileID: userProfile.userID.asString,
                                                               roomID: roomID,
                                                               accessToken: userProfile.accessToken)
        }.then { chatUserMuteStatusResource in
            completion(.success(ChatUserMuteStatus(isMuted: chatUserMuteStatusResource.isMuted)))
        }.catch { error in
            log.error("Error getting chat user muted status: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: Widgets
    
    /// Retrieve widget details of a widget by `id` and `kind`
    func getWidget(id: String,
                   kind: WidgetKind,
                   completion: @escaping (Result<Widget, Error>) -> Void) {
        firstly {
            Promises.zip(
                whenWidgetModelFactory,
                livelikeRestAPIService.getWidget(id: id, kind: kind)
            )
        }.then { widgetModelFactory, widgetResource in
            let widgetModel = try widgetModelFactory.make(from: widgetResource)
            guard let widget = DefaultWidgetFactory.makeWidget(from: widgetModel) else {
                throw GetWidgetError.widgetDoesNotExist
            }
            completion(.success(widget))
        }.catch { error in
            log.error("Error retrieving widget: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func getLeaderboardClients(leaderboardIDs: [String], completion: @escaping (Result<[LeaderboardClient], Error>) -> Void) {
        firstly {
            self.livelikeIDVendor.whenLiveLikeID
        }.then { livelikeID in
            Promises.all(leaderboardIDs.map {
                self.getLeaderboardAndCurrentEntry(leaderboardID: $0, profileID: livelikeID.asString)
            })
        }.then { leaderboardEntriesResponse in
            let leaderboards = leaderboardEntriesResponse.map {
                LeaderboardClient(
                    leaderboardResource: $0.leaderboard,
                    currentLeaderboardEntry: $0.currentEntry,
                    leaderboardsManager: self.leaderboardsManager
                )
            }
            completion(.success(leaderboards))
        }.catch { error in
            log.error("Error retrieving Leaderboards: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: Gamification
    
    /// Retrieves leaderboards for a given program
    func getLeaderboards(programID: String, completion: @escaping (Result<[Leaderboard], Error>) -> Void) {
        firstly {
            livelikeRestAPIService.getLeaderboards(programID: programID)
        }.then { leaderboardsResources in
            
            // Convert to integrator facing class
            let leaderboards = leaderboardsResources.map { leaderboard -> Leaderboard in
                let leaderboardReqard = LeaderboardReward(id: leaderboard.rewardItem.id, name: leaderboard.rewardItem.name)
                return Leaderboard(id: leaderboard.id, name: leaderboard.name, rewardItem: leaderboardReqard)
            }
        
            completion(.success(leaderboards))
        }.catch { error in
            log.error("Error retrieving Leaderboards: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Retrieves leaderboard details
    func getLeaderboard(leaderboardID: String, completion: @escaping (Result<Leaderboard, Error>) -> Void) {
        firstly {
            livelikeRestAPIService.getLeaderboard(leaderboardID: leaderboardID)
        }.then { leaderboard in
            completion(.success(Leaderboard(id: leaderboard.id,
                                            name: leaderboard.name,
                                            rewardItem: LeaderboardReward(id: leaderboard.rewardItem.id,
                                                                          name: leaderboard.rewardItem.name))))
        }.catch { error in
            log.error("Error retrieving Leaderboard: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Retrieves a paginated list of leaderboard entries
    func getLeaderboardEntries(
        leaderboardID: String,
        page: Pagination,
        completion: @escaping (Result<LeaderboardEntriesResult, Error>) -> Void
    ) {
        
        let leaderboardEntriesPromise = PromiseTask { () -> Promise<Void> in
            return Promise<Void> { [weak self] fulfill, reject in
                guard let self = self else { return }
                
                firstly {
                    Promises.zip(self.livelikeRestAPIService.getLeaderboard(leaderboardID: leaderboardID),
                                 self.accessTokenVendor.whenAccessToken)
                }.then { leaderboard, accessToken -> Promise<PaginatedResource<LeaderboardEntryResource>> in
                   
                    // Handle `.next`, `.previous` cases and their availibility
                    var notFirstPageUrl: URL?
                    switch page {
                    case .first:
                        // reset next/prev urls stored from previous calls to a different room
                        self.leaderboardEntriesPagination = PaginationProgress()
                    case .next:
                        guard let nextPageUrl = self.leaderboardEntriesPagination.next  else {
                            log.info("Next leaderboard entries page is unavailable")
                            return Promise(value: PaginatedResource(previous: nil,
                                                                      count: self.leaderboardEntriesPagination.total,
                                                                      next: nil,
                                                                      results: []))
                        }
                        notFirstPageUrl = nextPageUrl
                    case .previous:
                        guard let previousPageUrl = self.leaderboardEntriesPagination.previous  else {
                            log.info("Previous leaderboard entries page is unavailable")
                            return Promise(value: PaginatedResource(previous: nil,
                                                                      count: self.leaderboardEntriesPagination.total,
                                                                      next: nil,
                                                                      results: []))
                        }
                        notFirstPageUrl = previousPageUrl
                    }
                    
                    return self.livelikeRestAPIService.getLeaderboardEntries(
                        url: notFirstPageUrl ?? leaderboard.entriesUrl,
                        accessToken: accessToken
                    )
                }.then { leaderboardEntriesResult in
                    self.leaderboardEntriesPagination.total = leaderboardEntriesResult.count
                    self.leaderboardEntriesPagination.next = leaderboardEntriesResult.next
                    self.leaderboardEntriesPagination.previous = leaderboardEntriesResult.previous
                    let hasPrevious: Bool = leaderboardEntriesResult.previous != nil
                    let hasNext: Bool = leaderboardEntriesResult.next != nil
                    let leaderboardEntries = leaderboardEntriesResult.results.map { leaderboardEntry -> LeaderboardEntry in
                        return LeaderboardEntry(percentileRank: leaderboardEntry.percentileRank,
                                                profileId: leaderboardEntry.profileId,
                                                rank: leaderboardEntry.rank,
                                                score: leaderboardEntry.score,
                                                profileNickname: leaderboardEntry.profileNickname)
                    }
                    
                    completion(.success(LeaderboardEntriesResult(entries: leaderboardEntries,
                                                                 total: leaderboardEntriesResult.count,
                                                                 hasPrevious: hasPrevious,
                                                                 hasNext: hasNext)))
                    fulfill(())
                    
                }.catch { error in
                    log.error("Error retrieving Leaderboard Entries: \(error.localizedDescription)")
                    completion(.failure(error))
                    reject(error)
                }
                
            }
        }
        
        leaderboardEnriesPromiseQueue.enque(promiseTask: leaderboardEntriesPromise)
        
    }
    
    /// Get a leaderboard entry profile
    func getLeaderboardEntry(
        profileID: String,
        leaderboardID: String,
        completion: @escaping (Result<LeaderboardEntry, Error>) -> Void
    ) {
        firstly {
            self.getLeaderboardAndCurrentEntry(leaderboardID: leaderboardID, profileID: profileID)
        }.then { leaderboardAndEntry in
            guard let entryResource = leaderboardAndEntry.currentEntry else {
                completion(.failure(NilError()))
                return
            }
            let entry = LeaderboardEntry(
                percentileRank: entryResource.percentileRank,
                profileId: profileID,
                rank: entryResource.rank,
                score: entryResource.score,
                profileNickname: entryResource.profileNickname
            )
            completion(.success(entry))
        }.catch { error in
            log.error("Error retrieving Leaderboard Entries: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Get a leaderboard entry profile
    func getLeaderboardEntryForCurrentProfile(
        leaderboardID: String,
        completion: @escaping (Result<LeaderboardEntry, Error>) -> Void
    ) {
        firstly {
            userProfileVendor.whenProfileResource
        }.then { userProfile in
            self.getLeaderboardEntry(profileID: userProfile.id,
                                     leaderboardID: leaderboardID,
                                     completion: completion)
        }.catch { error in
            log.error("Error retrieving Leaderboard Entries: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}

// MARK: - Private APIs

private extension EngagementSDK {
    var eventRecorder: EventRecorder { return analytics }
    var identityRecorder: IdentityRecorder { return analytics }
    var peoplePropertyRecorder: PeoplePropertyRecorder { return analytics }
    var superPropertyRecorder: SuperPropertyRecorder { return analytics }
    
    func loadChatRoom(
        config: ChatSessionConfig,
        completion: @escaping (Result<InternalChatSessionProtocol, Error>) -> Void
    ) {
        firstly {
            return Promises.zip(
                self.livelikeRestAPIService.whenApplicationConfig,
                self.accessTokenVendor.whenAccessToken
            )
        }.then { application, accessToken in
            return Promises.zip(
                .init(value: application),
                self.livelikeIDVendor.whenLiveLikeID,
                self.accessTokenVendor.whenAccessToken,
                self.livelikeRestAPIService.getChatRoomResource(roomID: config.roomID, accessToken: accessToken)
            )
        }.then { application, livelikeid, accessToken, chatRoomResource in
            guard let chatPubnubChannel = chatRoomResource.channels.chat.pubnub else {
                return
            }

            let chatId = ChatUser.ID(idString: livelikeid.asString)
            let pubsubService = self.chatMessagingClient(
                appConfig: application,
                userID: chatId,
                nickname: self.userNicknameService,
                accessToken: accessToken
            )

            guard let chatChannel = pubsubService?.subscribe(chatPubnubChannel) else {
                return
            }

            let imageUploader = ImageUploader(
                uploadUrl: chatRoomResource.uploadUrl,
                urlSession: EngagementSDK.networking.urlSession,
                accessToken: accessToken
            )
           
            let reactionVendor = ChatRoomReactionVendor(
                reactionPacksUrl: chatRoomResource.reactionPacksUrl
            )

            let messageReporter = APIMessageReporter(
                reportURL: chatRoomResource.reportMessageUrl,
                accessToken: accessToken
            )

            let stickerRepository = StickerRepository(stickerPacksURL: chatRoomResource.stickerPacksUrl)
            
            let chatRoom: InternalChatSessionProtocol = PubSubChatRoom(
                roomID: chatRoomResource.id,
                chatChannel: chatChannel,
                userID: chatId,
                nickname: self.userNicknameService,
                imageUploader: imageUploader,
                analytics: self.analytics,
                reactionsVendor: reactionVendor,
                messageHistoryLimit: config.messageHistoryLimit,
                messageReporter: messageReporter,
                title: chatRoomResource.title,
                chatFilters: Set([.filtered]),
                stickerRepository: stickerRepository,
                shouldDisplayAvatar: config.shouldDisplayAvatar
            )
            completion(.success(chatRoom))
        }.catch { error in
            completion(.failure(error))
        }
    }

    func contentSessionInternal(config: SessionConfiguration, delegate: ContentSessionDelegate?) -> ContentSession {
        if whenMessagingClients.isRejected {
            log.severe("Cannot start a Content Session because the Engagement SDK failed to initialize.")
            whenMessagingClients = messagingClientPromise()
        }

        let programDetailVendor = ProgramDetailClient(programID: config.programID, applicationVendor: self.livelikeRestAPIService)

        return InternalContentSession(sdkInstance: self,
                                      config: config,
                                      whenMessagingClients: whenMessagingClients,
                                      livelikeIDVendor: livelikeIDVendor,
                                      nicknameVendor: userNicknameService,
                                      programDetailVendor: programDetailVendor,
                                      whenAccessToken: accessTokenVendor.whenAccessToken,
                                      eventRecorder: eventRecorder,
                                      superPropertyRecorder: superPropertyRecorder,
                                      peoplePropertyRecorder: peoplePropertyRecorder,
                                      livelikeRestAPIService: livelikeRestAPIService,
                                      widgetVotes: predictionVoteRepo,
                                      leaderboardsManager: self.leaderboardsManager,
                                      delegate: delegate)
    }

    func messagingClientPromise() -> Promise<InternalContentSession.MessagingClients> {
        return Promises.retry(count: 3, delay: 2.0) { () -> Promise<InternalContentSession.MessagingClients> in
            firstly {
                self.livelikeRestAPIService.whenApplicationConfig
                
            }.then(on: DispatchQueue.global()) { configuration -> Promise<(ApplicationConfiguration, LiveLikeID, String, AccessToken)> in
                log.info("Successfully initialized the Engagement SDK!")
                self.whenProgramURLTemplate.fulfill(configuration.programDetailUrlTemplate)
                return Promises.zip(.init(value: configuration),
                                    self.livelikeIDVendor.whenLiveLikeID,
                                    self.userNicknameService.whenInitialNickname,
                                    self.accessTokenVendor.whenAccessToken)
                
            }.then { values -> InternalContentSession.MessagingClients in
                let (configuration, id, nickname, accessToken) = values
                self.identityRecorder.identify(id: id.asString)
                
                self.superPropertyRecorder.register([.nickname(nickname: nickname)])
                self.peoplePropertyRecorder.record([
                    .name(name: nickname),
                    .sdkVersion(sdkVersion: EngagementSDK.version),
                    .nickname(nickname: nickname),
                    .operatingSystem(os: "iOS")
                ])
                
                if let officialAppName = Bundle.main.displayName {
                    self.peoplePropertyRecorder.record([.officialAppName(officialAppName: officialAppName)])
                }
                
                self.orientationAnalytics.shouldRecord = true
                let userID = ChatUser.ID(idString: id.asString)
                
                var widgetClient: WidgetClient?
                if let subscribeKey = configuration.pubnubSubscribeKey {
                    widgetClient = self.widgetMessagingClient(
                        subcribeKey: subscribeKey,
                        origin: configuration.pubnubOrigin,
                        userID: userID.asString
                    )
                }
                
                let pubsubService = self.chatMessagingClient(
                    appConfig: configuration,
                    userID: userID,
                    nickname: self.userNicknameService,
                    accessToken: accessToken
                )
                let messagingClient = InternalContentSession.MessagingClients(userId: id.asString, widgetMessagingClient: widgetClient, pubsubService: pubsubService)
                
                self.whenInitializedAndReady.fulfill(())
                return messagingClient
            }
        }
    }

}

// MARK: - WidgetPauser

extension EngagementSDK: WidgetPauser {
    private static let permanentPauseUserDefaultsKey = "EngagementSDK.widgetsPausedForAllSessions"

    func setDelegate(_ delegate: PauseDelegate) {
        widgetPauseDelegates.addListener(delegate)
    }

    func removeDelegate(_ delegate: PauseDelegate) {
        widgetPauseDelegates.removeListener(delegate)
    }

    func pauseWidgets() {
        widgetPauseStatus = .paused
    }

    func resumeWidgets() {
        widgetPauseStatus = .unpaused
    }
}

// MARK: - WidgetCrossSessionPauser

extension EngagementSDK: WidgetCrossSessionPauser {
    /**
     Pauses widgets for all ContentSessions
     This is stored in UserDefaults and will persist on future app launches
     */
     public func pauseWidgetsForAllContentSessions() {
        pauseWidgets()
    }

    /**
     Resumes widgets for all ContentSessions
     This is stored in UserDefaults and will persist on future app launches
     */
     public func resumeWidgetsForAllContentSessions() {
        resumeWidgets()
    }
}

extension EngagementSDK: InternalErrorDelegate {
    // Repeat errors to the intergrator delegate
    func setupError(_ error: EngagementSDK.SetupError) {
        delegate?.sdk?(self, setupFailedWithError: error)
    }
}
