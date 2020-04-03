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
@objc(LLEngagementSDK)
public class EngagementSDK: NSObject {
    // MARK: - Static Properties

    // MARK: Internal

    static let networking: SDKNetworking = SDKNetworking(sdkVersion: EngagementSDK.version)
    static let prodAPIEndpoint: URL = URL(string: "https://cf-blast.livelikecdn.com/api/v1")!

    // MARK: - Stored Properties

    // MARK: Public

    /// The sdk's delegate, currently only used to report setup errors
    @objc
    public weak var delegate: EngagementSDKDelegate?

    // MARK: Internal

    private(set) var clientID: String
    private(set) var whenInitializedAndReady: Promise<Void> = Promise()

    var widgetPauseStatus: PauseStatus {
        didSet {
            UserDefaults.standard.set(areWidgetsPausedForAllSessions, forKey: EngagementSDK.permanentPauseUserDefaultsKey)
            widgetPauseDelegates.publish { $0.pauseStatusDidChange(status: self.widgetPauseStatus) }
        }
    }

    // MARK: Private

    private var whenMessagingClients: Promise<InternalContentSession.MessagingClients>!
    private var applicationConfigVendor: ApplicationConfigVendor
    private var whenProgramURLTemplate: Promise<String>
    private let stickerRepository: StickerRepository
    private let syncSessionClient: SyncSessionClient
    private let accessTokenVendor: AccessTokenVendor
    private let livelikeIDVendor: LiveLikeIDVendor
    private let userNicknameService: UserNicknameService
    private let userPointsVendor: UserPointsVendor
    private let sdkErrorReporter: InternalErrorReporter

    private let widgetPauseDelegates: Listener<PauseDelegate> = Listener<PauseDelegate>()
    private let analytics: Analytics

    private lazy var orientationAnalytics = OrientationChangeAnalytics(eventRecorder: self.eventRecorder,
                                                                       superPropertyRecorder: self.superPropertyRecorder,
                                                                       peoplePropertyRecorder: self.peoplePropertyRecorder)

    // MARK: - Initialization
    
    convenience init(clientID: String, apiEndpointURL: URL, accessTokenStorage: AccessTokenStorage) {
        let appConfigVendor = ApplicationConfigClient(apiBaseURL: apiEndpointURL, clientID: clientID)
        
        let sdkErrorReporter = InternalErrorReporter()
        let accessTokenGenerator = APIAccessTokenGenerator(applicationConfigVendor: appConfigVendor)
        let userProfileService = APIUserProfileService(appConfigVendor: appConfigVendor)
        
        let userResolver = UserResolver(accessTokenStorage: accessTokenStorage,
                                        userProfileService: userProfileService,
                                        accessTokenGenerator: accessTokenGenerator,
                                        sdkDelegate: sdkErrorReporter)

        self.init(clientID: clientID,
                  apiEndpoint: apiEndpointURL,
                  applicationConfigVendor: appConfigVendor,
                  accessTokenVendor: userResolver,
                  livelikeIDVendor: userResolver,
                  userNicknameService: userResolver,
                  userPointsVendor: userResolver,
                  awardsProfileVendor: userResolver,
                  sdkErrorReporter: sdkErrorReporter)
    }

    internal init(clientID: String,
                  apiEndpoint: URL,
                  applicationConfigVendor: ApplicationConfigVendor,
                  accessTokenVendor: AccessTokenVendor,
                  livelikeIDVendor: LiveLikeIDVendor,
                  userNicknameService: UserNicknameService,
                  userPointsVendor: UserPointsVendor,
                  awardsProfileVendor: AwardsProfileVendor,
                  sdkErrorReporter: InternalErrorReporter) {
        self.clientID = clientID
        self.accessTokenVendor = accessTokenVendor
        self.applicationConfigVendor = applicationConfigVendor
        self.livelikeIDVendor = livelikeIDVendor
        self.userNicknameService = userNicknameService
        self.userPointsVendor = userPointsVendor
        self.sdkErrorReporter = sdkErrorReporter
        syncSessionClient = APISyncSessionClient()
        analytics = Analytics(applicationConfigVendor: applicationConfigVendor)
        whenProgramURLTemplate = Promise<String>()
        log.info("Initializing EngagementSDK using client id: '\(clientID)'")
        widgetPauseStatus = UserDefaults.standard.bool(forKey: EngagementSDK.permanentPauseUserDefaultsKey) == true ? .paused : .unpaused
        stickerRepository = StickerRepository(apiBaseURL: apiEndpoint)
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
                delegateError = SetupError.invalidClientID(clientID)
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
    }
}

// MARK: - Static Public APIs

public extension EngagementSDK {
    /// A property to control the level of logging from the `EngagementSDK`.
    @objc
    static var logLevel: LogLevel {
        get { return Logger.LoggingLevel }
        set { Logger.LoggingLevel = newValue }
    }
}

// MARK: - Public APIs

public extension EngagementSDK {
    /// A delegate that returns analytics events.
    @objc
    var analyticsDelegate: EngagementAnalyticsDelegate? {
        get { return analytics.delegate }
        set { analytics.delegate = newValue }
    }

    /// Returns whether widgets are paused for all sessions
    @objc
    var areWidgetsPausedForAllSessions: Bool {
        return widgetPauseStatus == .paused
    }

    /**
     Creates a new `ContentSession` instance using a SessionConfiguration object.

     - Parameter config: A configuration object that defines the properties for a `ContentSession`
     - Parameter delegate: an object that will act as the delegate of the content session.
     - Returns: returns the `ContentSession`
     */
    @objc
    func contentSession(config: SessionConfiguration, delegate: ContentSessionDelegate) -> ContentSession {
        return contentSessionInternal(config: config, delegate: delegate)
    }

    /**
     Creates a new `ContentSession` instance using a SessionConfiguration object.

     - Parameter config: A configuration object that defines the properties for a `ContentSession`
     - Returns: returns the `ContentSession`
     */
    @objc
    func contentSession(config: SessionConfiguration) -> ContentSession {
        return contentSessionInternal(config: config, delegate: nil)
    }

    /**
     - Parameter clientID: Find more information regarding the Client ID in our [Basic Integration documentation](https://docs.livelike.com/ios/index.html#initialization)
     - Note: This initializer will cause the SDK to use UserDefaults for storing the user access token.
     */
    @objc
    convenience init(clientID: String) {
        self.init(clientID: clientID,
                  apiEndpointURL: EngagementSDK.prodAPIEndpoint,
                  accessTokenStorage: UserDefaultsAccessTokenStorage())
    }
    
    /**
     - Parameter clientID: Find more information regarding the Client ID in our [Basic Integration documentation](https://docs.livelike.com/ios/index.html#initialization)
     - Parameter accessTokenStorage: An object which the EngagementSDK uses to check for a stored access token between sessions, as well as to inform the storage of a newly generated token.
     */
    @objc
    convenience init(clientID: String, accessTokenStorage: AccessTokenStorage) {
        self.init(clientID: clientID,
                  apiEndpointURL: EngagementSDK.prodAPIEndpoint,
                  accessTokenStorage: accessTokenStorage)
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
    @objc
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
}

// MARK: - Private APIs

private extension EngagementSDK {
    var eventRecorder: EventRecorder { return analytics }
    var identityRecorder: IdentityRecorder { return analytics }
    var peoplePropertyRecorder: PeoplePropertyRecorder { return analytics }
    var superPropertyRecorder: SuperPropertyRecorder { return analytics }

    func contentSessionInternal(config: SessionConfiguration, delegate: ContentSessionDelegate?) -> ContentSession {
        if whenMessagingClients.isRejected {
            log.severe("Cannot start a Content Session because the Engagement SDK failed to initialize.")
            whenMessagingClients = messagingClientPromise()
        }

        let programDetailVendor = ProgramDetailClient(programID: config.programID, applicationVendor: self.applicationConfigVendor)
        let reactionVendor = ProgramChatReactionsVendor(programDetailVendor: programDetailVendor, cache: Cache.shared)

        return InternalContentSession(sdkInstance: self,
                                      config: config,
                                      whenMessagingClients: whenMessagingClients,
                                      livelikeIDVendor: livelikeIDVendor,
                                      nicknameVendor: userNicknameService,
                                      userPointsVendor: userPointsVendor,
                                      networkClient: syncSessionClient,
                                      programDetailVendor: programDetailVendor,
                                      stickerRepository: stickerRepository,
                                      whenAccessToken: accessTokenVendor.whenAccessToken,
                                      eventRecorder: eventRecorder,
                                      superPropertyRecorder: superPropertyRecorder,
                                      peoplePropertyRecorder: peoplePropertyRecorder,
                                      reactionVendor: reactionVendor,
                                      appConfigVendor: applicationConfigVendor,
                                      delegate: delegate)
    }

    func messagingClientPromise() -> Promise<InternalContentSession.MessagingClients> {
        return Promises.retry(count: 3, delay: 2.0) { () -> Promise<InternalContentSession.MessagingClients> in
            firstly {
                self.applicationConfigVendor.whenApplicationConfig
                
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
                
                var widgetClient: (WidgetClient & SyncMessagingClient)?
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
    @objc public func pauseWidgetsForAllContentSessions() {
        pauseWidgets()
    }

    /**
     Resumes widgets for all ContentSessions
     This is stored in UserDefaults and will persist on future app launches
     */
    @objc public func resumeWidgetsForAllContentSessions() {
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
