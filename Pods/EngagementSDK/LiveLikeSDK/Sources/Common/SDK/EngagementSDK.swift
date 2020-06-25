//
//  ViewController.swift
//  Test
//
//  Created by Cory Sullivan on 2019-01-11.
//  Copyright © 2019 Cory Sullivan. All rights reserved.
//

import UIKit
import Bugsnag

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
    private let userPointsVendor: UserPointsVendor
    private let userProfileVendor: UserProfileVendor
    private let sdkErrorReporter: InternalErrorReporter
    private let widgetVotes = WidgetVotes()

    private let widgetPauseDelegates: Listener<PauseDelegate> = Listener<PauseDelegate>()
    private let analytics: Analytics

    private lazy var orientationAnalytics = OrientationChangeAnalytics(eventRecorder: self.eventRecorder,
                                                                       superPropertyRecorder: self.superPropertyRecorder,
                                                                       peoplePropertyRecorder: self.peoplePropertyRecorder)

    // MARK: - Initialization
    
    /// Initializes an instance of the EngagementSDK
    /// - Parameter config: An EngagementSDKConfig object
    public convenience init(config: EngagementSDKConfig) {
        let livelikeRestAPIService = LiveLikeRestAPIServices(apiBaseURL: config.apiOrigin, clientID: config.clientID)
        
        let sdkErrorReporter = InternalErrorReporter()
        let accessTokenGenerator = APIAccessTokenGenerator(livelikeRestAPIService: livelikeRestAPIService)
        let userProfileService = APIUserProfileService(livelikeRestAPIService: livelikeRestAPIService)
        
        let userResolver = UserResolver(accessTokenStorage: config.accessTokenStorage,
                                        userProfileService: userProfileService,
                                        accessTokenGenerator: accessTokenGenerator,
                                        sdkDelegate: sdkErrorReporter)
        
        let bugsnagAPIKey: String = {
            guard
                let key = Bundle(for: EngagementSDK.self).object(forInfoDictionaryKey: "BugsnagAPIKey") as? String,
                key != ""
            else {
                log.error("Failed to find Bugsnag API Key.")
                return ""
            }
            return key
        }()

        self.init(
            config: config,
            livelikeRestAPIService: livelikeRestAPIService,
            accessTokenVendor: userResolver,
            livelikeIDVendor: userResolver,
            userNicknameService: userResolver,
            userPointsVendor: userResolver,
            userProfileVendor: userResolver,
            awardsProfileVendor: userResolver,
            sdkErrorReporter: sdkErrorReporter,
            bugsnagAPIKey: bugsnagAPIKey
        )
    }

    internal init(
        config: EngagementSDKConfig,
        livelikeRestAPIService: LiveLikeRestAPIServicable,
        accessTokenVendor: AccessTokenVendor,
        livelikeIDVendor: LiveLikeIDVendor,
        userNicknameService: UserNicknameService,
        userPointsVendor: UserPointsVendor,
        userProfileVendor: UserProfileVendor,
        awardsProfileVendor: AwardsProfileVendor,
        sdkErrorReporter: InternalErrorReporter,
        bugsnagAPIKey: String
    ) {
        self.config = config
        self.accessTokenVendor = accessTokenVendor
        self.livelikeRestAPIService = livelikeRestAPIService
        self.livelikeIDVendor = livelikeIDVendor
        self.userNicknameService = userNicknameService
        self.userPointsVendor = userPointsVendor
        self.userProfileVendor = userProfileVendor
        self.sdkErrorReporter = sdkErrorReporter
        analytics = Analytics(livelikeRestAPIService: livelikeRestAPIService)
        whenProgramURLTemplate = Promise<String>()
        log.info("Initializing EngagementSDK using client id: '\(config.clientID)'")
        widgetPauseStatus = UserDefaults.standard.bool(forKey: EngagementSDK.permanentPauseUserDefaultsKey) == true ? .paused : .unpaused
        super.init()
        sdkErrorReporter.delegate = self
        awardsProfileVendor.addDelegate(self)
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
        /// 3. Initialize third parties (Bugsnag)
        firstly {
            Promises.zip(
                self.livelikeRestAPIService.whenApplicationConfig,
                self.userNicknameService.whenInitialNickname,
                self.livelikeIDVendor.whenLiveLikeID
            )
        }.then { appConfig, nickname, livelikeID in
            if config.isBugsnagEnabled {
                self.initializeBugsnag(
                    apiKey: bugsnagAPIKey,
                    organizationID: appConfig.organizationId,
                    organizationName: appConfig.organizationName,
                    userID: livelikeID.asString,
                    userNickname: nickname
                )
            }
            self.delegate?.sdk?(setupCompleted: self)
        }.catch { error in
            switch error {
            case NetworkClientError.badRequest:
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
    
    /// Create an instance of a `Widget` which can be placed into your view.
    /// - Parameters:
    ///   - jsonObject: A JSON object compatable with `JSONSerialization.data(withJSONObject:options:)`
    ///   - completion: A result containing the `Widget`
    func createWidget(withJSONObject jsonObject: Any, completion: @escaping (Result<WidgetController, Error>) -> Void) {
        firstly {
            Promises.zip(
                self.whenMessagingClients,
                self.accessTokenVendor.whenAccessToken
            )
        }.then { messagingClients, accessToken in
            guard let widgetClient = messagingClients.widgetMessagingClient else {
                return
            }
            let clientEvent = try WidgetPayloadParser.parse(jsonObject)
            let widgetFactory = ClientEventWidgetFactory(
                event: clientEvent,
                voteRepo: self.widgetVotes,
                widgetMessagingOutput: widgetClient,
                accessToken: accessToken,
                eventRecorder: self.eventRecorder
            )
            guard let widget = widgetFactory.create(widgetConfig: WidgetConfig()) else {
                return
            }
            completion(.success(widget))
        }.catch { error in
            completion(.failure(error))
        }
    }
    
    func createWidgets(
        widgetJSONObjects jsonObjects: [Any],
        completion: @escaping (Result<[Widget], Error>) -> Void
    ) {
        firstly {
            Promises.zip(
                self.whenMessagingClients,
                self.accessTokenVendor.whenAccessToken
            )
        }.then { messagingClients, accessToken in
            guard let widgetClient = messagingClients.widgetMessagingClient else {
                return
            }
            DispatchQueue.main.async {
                let widgets: [Widget] = jsonObjects.compactMap { jsonObject in
                    guard let clientEvent = try? WidgetPayloadParser.parse(jsonObject) else {
                        return nil
                    }
                    let widgetFactory = ClientEventWidgetFactory(
                        event: clientEvent,
                        voteRepo: self.widgetVotes,
                        widgetMessagingOutput: widgetClient,
                        accessToken: accessToken,
                        eventRecorder: self.eventRecorder
                    )
                    return widgetFactory.create(widgetConfig: WidgetConfig())
                }
                completion(.success(widgets))
            }
        }.catch { error in
            completion(.failure(error))
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
    
    /// Sets a user's display name and calls the completion block
    func setUserDisplayName(_ newDisplayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        // swiftlint:disable nesting
        enum Error: Swift.Error, LocalizedError {
            case invalidNameLength
            var errorDescription: String? { return "Display names must be between 1 and 20 characters" }
        }
        // swiftlint:enable nesting
        
        guard (1...20).contains(newDisplayName.count) else {
            completion(.failure(Error.invalidNameLength))
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
    
    /// Creates a chat room with an optional title
    func createChatRoom(title: String?,
                        completion: @escaping (Result<String, Error>) -> Void) {
        firstly {
            Promises.zip(self.accessTokenVendor.whenAccessToken,
                         self.livelikeRestAPIService.whenApplicationConfig)
        }.then { accessToken, appConfig -> Promise<ChatRoomResource> in
            self.livelikeRestAPIService.createChatRoomResource(title: title,
                                                         accessToken: accessToken,
                                                         appConfig: appConfig)
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
            livelikeRestAPIService.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource in
            completion(.success(ChatRoomInfo(id: chatRoomResource.id, title: chatRoomResource.title)))
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
        }.then { accessToken -> Promise<[ChatRoomMember]> in
            self.livelikeRestAPIService.getChatRoomMemberships(roomID: roomID,
                                                               page: page,
                                                               accessToken: accessToken)
        }.then { chatRoomMembers in
             completion(.success(chatRoomMembers))
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
        }.then { accessToken, profileResource -> Promise<[ChatRoomInfo]> in
            self.livelikeRestAPIService.getUserChatRoomMemberships(profile: profileResource,
                                                                   accessToken: accessToken,
                                                                   page: page)
        }.then { userChatRoomMemberships in
             completion(.success(userChatRoomMemberships))
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
}

// MARK: - Private APIs

private extension EngagementSDK {
    
    private func initializeBugsnag(
        apiKey: String,
        organizationID: String,
        organizationName: String,
        userID: String,
        userNickname: String
    ){
        let config = BugsnagConfiguration()
        config.apiKey = apiKey
        config.appVersion = "\(Bundle.main.displayName ?? "UNKNOWN APP NAME") (\(EngagementSDK.version))"
        #if DEBUG
        config.releaseStage = "development"
        #endif
        config.setUser(userID, withName: userNickname, andEmail: nil)
        Bugsnag.start(with: config)
    }
    
    private func loadChatRoom(
        config: ChatSessionConfig,
        completion: @escaping (Result<InternalChatSessionProtocol, Error>) -> Void
    ) {
        firstly {
            self.livelikeRestAPIService.whenApplicationConfig
        }.then { application in
            return Promises.zip(
                .init(value: application),
                self.livelikeIDVendor.whenLiveLikeID,
                self.accessTokenVendor.whenAccessToken,
                self.livelikeRestAPIService.getChatRoomResource(roomID: config.roomID)
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
           
            let reactionVendor = ChatRoomReactionVendor(reactionPacksUrl: chatRoomResource.reactionPacksUrl,
                                                         cache: Cache.shared)

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
                eventRecorder: self.eventRecorder,
                reactionsViewModelFactory:
                    ReactionsViewModelFactory(
                        reactionAssetsVendor: reactionVendor,
                        mediaRepository: EngagementSDK.mediaRepository
                    ),
                reactionsVendor: reactionVendor,
                messageHistoryLimit: config.messageHistoryLimit,
                messageReporter: messageReporter,
                title: chatRoomResource.title,
                chatFilters: Set([.filtered]),
                stickerRepository: stickerRepository
            )
            completion(.success(chatRoom))
        }.catch { error in
            completion(.failure(error))
        }
    }

    var eventRecorder: EventRecorder { return analytics }
    var identityRecorder: IdentityRecorder { return analytics }
    var peoplePropertyRecorder: PeoplePropertyRecorder { return analytics }
    var superPropertyRecorder: SuperPropertyRecorder { return analytics }

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
                                      userPointsVendor: userPointsVendor,
                                      programDetailVendor: programDetailVendor,
                                      whenAccessToken: accessTokenVendor.whenAccessToken,
                                      eventRecorder: eventRecorder,
                                      superPropertyRecorder: superPropertyRecorder,
                                      peoplePropertyRecorder: peoplePropertyRecorder,
                                      livelikeRestAPIService: livelikeRestAPIService,
                                      widgetVotes: widgetVotes,
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
                
                var widgetClient: WidgetClient?
                if let subscribeKey = configuration.pubnubSubscribeKey {
                    widgetClient = self.widgetMessagingClient(
                        subcribeKey: subscribeKey,
                        origin: configuration.pubnubOrigin
                    )
                }
                
                let chatId = ChatUser.ID(idString: id.asString)
                let pubsubService = self.chatMessagingClient(
                    appConfig: configuration,
                    userID: chatId,
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

extension EngagementSDK: AwardsProfileDelegate {
    func awardsProfile(didUpdate awardsProfile: AwardsProfile) {
        analytics.register([.lifetimePoints(points: Int(awardsProfile.totalPoints))])
        analytics.record([.lifetimePoints(points: Int(awardsProfile.totalPoints))])
    }
}
