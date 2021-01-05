//
//  InternalContentSession.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dams on 2019-01-18.
//

import AVFoundation
import UIKit

//typealias ChatMessagingOutput = ChatRoom & ChatProxyOutput
public typealias PlayerTimeSource = (() -> TimeInterval?)

/// Concrete implementation of `ContentSession`
class InternalContentSession: ContentSession {

    struct MessagingClients {
        var userId: String

        /// The `WidgetMessagingClient` to be used for this session
        var widgetMessagingClient: WidgetClient?

        var pubsubService: PubSubService?
    }

    var messagingClients: MessagingClients?
    var widgetChannel: String?
    let rewardsURLRepo = RewardsURLRepo()

    var status: SessionStatus = .uninitialized {
        didSet {
            delegate?.session(self, didChangeStatus: status)
        }
    }

    var widgetPauseListeners = Listener<PauseDelegate>()
    private(set) var widgetPauseStatus: PauseStatus {
        didSet {
            timeWidgetPauseStatusChanged = Date()
            widgetPauseListeners.publish { $0.pauseStatusDidChange(status: self.widgetPauseStatus) }
        }
    }

    var config: SessionConfiguration

    var programID: String

    var playerTimeSource: PlayerTimeSource?
    var recentlyUsedStickers = LimitedArray<Sticker>(maxSize: 30)
    
    let superPropertyRecorder: SuperPropertyRecorder
    let peoplePropertyRecorder: PeoplePropertyRecorder

    /// Unique identifier to represent the session instance
    private var hashValue: String {
        return String(UInt(bitPattern: ObjectIdentifier(self)))
    }

    private let chatHistoryLimitRange = 0 ... 200
    private let whenMessagingClients: Promise<InternalContentSession.MessagingClients>
    let sdkInstance: EngagementSDK
    private let livelikeIDVendor: LiveLikeIDVendor
    let nicknameVendor: UserNicknameVendor
    private(set) var userPointsVendor: UserPointsVendor
    private let whenAccessToken: Promise<AccessToken>

    let livelikeRestAPIService: LiveLikeRestAPIServicable
    private let predictionVoteRepo: PredictionVoteRepository
    var sessionDidEnd: (() -> Void)?
    weak var delegate: ContentSessionDelegate? {
        didSet {
            if delegate != nil {
                initializeDelegatePlayheadTimeSource()
            }
        }
    }

    private lazy var whenWidgetModelFactory: Promise<WidgetModelFactory> = {
        return firstly {
            Promises.zip(
                sdkInstance.whenUserProfile,
                self.whenProgramDetail,
                self.whenAccessToken,
                self.whenMessagingClients
            )
        }.then { (userProfile, programResource, accessToken, messagingClient) in
            guard let widgetClient = messagingClient.widgetMessagingClient else { throw ContentSessionError.missingWidgetClient }
            let factory = WidgetModelFactory(
                eventRecorder: self.eventRecorder,
                userProfile: userProfile,
                rewardItems: programResource.rewardItems.map { RewardItem(id: $0.id, name: $0.name)},
                leaderboardsManager: self.leaderboardsManager,
                accessToken: accessToken,
                widgetClient: widgetClient,
                livelikeRestAPIService: self.livelikeRestAPIService,
                predictionVoteRepo: self.predictionVoteRepo
            )
            return Promise(value: factory)
        }
    }()

    private lazy var whenChatSession: Promise<ChatSession> = {
        return firstly {
            self.whenProgramDetail
        }.then { programDetail -> Promise<ChatSession> in
            guard let chatRoomResource = programDetail.defaultChatRoom else {
                return Promise(error: ContentSessionError.failedSettingsChatSessionDelegate)
            }

            return Promise { [weak self] fulfill, reject in
                guard let self = self else {
                    reject(ContentSessionError.failedSettingsChatSessionDelegate)
                    return
                }

                var chatConfig = ChatSessionConfig(roomID: chatRoomResource.id)
                chatConfig.shouldDisplayAvatar = self.config.chatShouldDisplayAvatar
                chatConfig.syncTimeSource = self.playerTimeSource
                
                self.sdkInstance.connectChatRoom(
                    config: chatConfig
                ) { result in
                    switch result {
                    case .success(let currentChatRoom):
                        self.currentChatRoom = currentChatRoom as? InternalChatSessionProtocol
                        fulfill(currentChatRoom)
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        }
    }()

    func getChatSession(completion: @escaping (Result<ChatSession, Error>) -> Void) {
        firstly {
            self.whenChatSession
        }.then { chatSession in
            completion(.success(chatSession))
        }.catch { error in
            completion(.failure(error))
        }
    }

    weak var player: AVPlayer?
    var periodicTimebaseObserver: Any?

    var gamificationManager: GamificationViewManager?
    var rankClient: RankClient?
    private var whenRankClient = Promise<RankClient>()
    private var nextWidgetTimelineUrl: URL?
    private var nextWidgetModelTimelineURL: URL?
    private let leaderboardsManager: LeaderboardsManager

    // Analytics properties

    var eventRecorder: EventRecorder
    private var timeWidgetPauseStatusChanged: Date = Date()
    
    private var sessionIsValid: Bool {
        if status == .ready {
            return true
        }
        delegate?.session(self, didReceiveError: SessionError.invalidSessionStatus(status))
        return false
    }

    private let whenProgramDetail: Promise<ProgramDetailResource>

    private(set) lazy var whenWidgetQueue: Promise<WidgetProxy> = {
        firstly {
            Promises.zip(self.whenMessagingClients,
                         self.livelikeIDVendor.whenLiveLikeID,
                         self.whenProgramDetail,
                         self.whenAccessToken
            )
        }.then { messagingClients, livelikeID, programDetail, accessToken -> Promise<WidgetProxy> in
            
            guard let widgetClient = messagingClients.widgetMessagingClient else {
                return Promise(error: ContentSessionError.missingWidgetClient)
            }
            
            guard let channel = programDetail.subscribeChannel else {
                return Promise(error: ContentSessionError.missingSubscribeChannel)
            }
            
            self.widgetChannel = channel
            
            let syncWidgetProxy = SynchronizedWidgetProxy(playerTimeSource: self.playerTimeSource)
            self.baseWidgetProxy = syncWidgetProxy
            widgetClient.addListener(syncWidgetProxy, toChannel: channel)
            
            let widgetQueue = syncWidgetProxy
                .addProxy {
                    let pauseProxy = PauseWidgetProxy(playerTimeSource: self.playerTimeSource,
                                                      initialPauseStatus: self.widgetPauseStatus)
                    self.widgetPauseListeners.addListener(pauseProxy)
                    return pauseProxy
                }
                .addProxy { WriteRewardsURLToRepoProxy(rewardsURLRepo: self.rewardsURLRepo) }
                .addProxy { ImageDownloadProxy() }
                .addProxy { WidgetLoggerProxy(playerTimeSource: self.playerTimeSource) }
                .addProxy {
                    OnPublishProxy { [weak self] publishData in
                        guard let self = self else { return }
                        guard case let ClientEvent.widget(widgetResource) = publishData.clientEvent else { return }

                        // Create WidgetDataObject
                        firstly {
                            self.whenWidgetModelFactory
                        }.then(on: DispatchQueue.main) { widgetModelFactory in
                            let widgetModel = try widgetModelFactory.make(from: widgetResource)
                            self.delegate?.contentSession(self, didReceiveWidget: widgetModel)

                            if let widgetController = DefaultWidgetFactory.makeWidget(from: widgetModel) {
                                self.delegate?.widget(self, didBecomeReady: widgetController)
                            }
                        }.catch { error in
                            log.error(error)
                        }
                    }
                }

            return Promise(value: widgetQueue)
        }
    }()
    
    private(set) lazy var whenRewards: Promise<Rewards> = {
        firstly {
            Promises.zip(self.whenAccessToken, self.whenProgramDetail, self.whenRankClient)
        }.then { accessToken, programResource, rankClient in
            let rewards = Rewards(rewardsURLRepo: self.rewardsURLRepo,
                                  rewardsClient: APIRewardsClient(accessToken: accessToken),
                                  rewardsType: programResource.rewardsType,
                                  superPropertyRecorder: self.superPropertyRecorder,
                                  peoplePropertyRecorder: self.peoplePropertyRecorder,
                                  rankClient: rankClient)
            return Promise(value: rewards)
        }
    }()

    /// Maintains a reference to the base widget proxy
    ///
    /// This allows us to remove it as a listener from the `WidgetMessagingClient`
    private var baseWidgetProxy: WidgetProxy?
    
    var currentChatRoom: InternalChatSessionProtocol?

    // MARK: -
    required init(sdkInstance: EngagementSDK,
                  config: SessionConfiguration,
                  whenMessagingClients: Promise<InternalContentSession.MessagingClients>,
                  livelikeIDVendor: LiveLikeIDVendor,
                  nicknameVendor: UserNicknameVendor,
                  userPointsVendor: UserPointsVendor,
                  programDetailVendor: ProgramDetailVendor,
                  whenAccessToken: Promise<AccessToken>,
                  eventRecorder: EventRecorder,
                  superPropertyRecorder: SuperPropertyRecorder,
                  peoplePropertyRecorder: PeoplePropertyRecorder,
                  livelikeRestAPIService: LiveLikeRestAPIServicable,
                  widgetVotes: PredictionVoteRepository,
                  leaderboardsManager: LeaderboardsManager,
                  delegate: ContentSessionDelegate? = nil)
    {
        self.config = config
        self.whenMessagingClients = whenMessagingClients
        self.livelikeIDVendor = livelikeIDVendor
        self.nicknameVendor = nicknameVendor
        self.userPointsVendor = userPointsVendor
        self.delegate = delegate
        programID = config.programID
        self.sdkInstance = sdkInstance
        widgetPauseStatus = sdkInstance.widgetPauseStatus
        self.whenAccessToken = whenAccessToken
        self.whenProgramDetail = programDetailVendor.getProgramDetails()
        self.eventRecorder = eventRecorder
        self.superPropertyRecorder = superPropertyRecorder
        self.peoplePropertyRecorder = peoplePropertyRecorder
        self.livelikeRestAPIService = livelikeRestAPIService
        self.predictionVoteRepo = widgetVotes
        self.leaderboardsManager = leaderboardsManager
        sdkInstance.setDelegate(self)

        initializeDelegatePlayheadTimeSource()

        initializeMixpanelProperties()
        initializeGamification()
        initializeRankClient()
        startSession()
        
        whenMessagingClients.then { [weak self] in
            guard let self = self else { return }
            self.messagingClients = $0
        }.catch {
            log.error($0.localizedDescription)
        }
    }
    
    private func initializeDelegatePlayheadTimeSource() {
        // If syncTimeSource given in config use that
        // Otherwise use the delegate until playheadTimeSource removed from delegate IOSSDK-1228
        if config.syncTimeSource != nil {
            playerTimeSource = { [weak self] in
                self?.config.syncTimeSource?()
            }
        } else {
            playerTimeSource = { [weak self] in
                if
                    let self = self,
                    let delegate = self.delegate
                {
                    return delegate.playheadTimeSource(self)?.timeIntervalSince1970
                }
                return nil
            }
        }
    }
    
    private func initializeMixpanelProperties() {
        superPropertyRecorder.register([
            .chatStatus(status: .enabled),
            .widgetStatus(status: .enabled),
            .pointsThisProgram(points: 0),
            .badgeLevelThisProgram(level: 0),
        ])
        peoplePropertyRecorder.record([
            .lastChatStatus(status: .enabled),
            .lastWidgetStatus(status: .enabled),
        ])
    }
    
    private func initializeGamification() {
        firstly {
            Promises.zip(whenWidgetQueue, whenRewards)
        }.then {
            let (widgetQueue, rewards) = $0
            self.gamificationManager = GamificationViewManager(
                rewards: rewards,
                eventRecorder: self.eventRecorder
            )
        }.catch { error in
            log.error("Failed to initialize Gamification with error: \(error.localizedDescription)")
        }
    }
    
    private func initializeRankClient() {
        firstly {
            Promises.zip(whenProgramDetail, whenAccessToken)
        }.then { programResource, accessToken in
            let rankClient = RankClient(rankURL: programResource.rankUrl, accessToken: accessToken, rewardsType: programResource.rewardsType)
            rankClient.addDelegate(self)
            self.rankClient = rankClient
            self.whenRankClient.fulfill(rankClient)
        }.catch { error in
            log.error("Failed to initialize RankClient with error: \(error.localizedDescription)")
        }
    }

    deinit {
        teardownSession()
        log.info("Content Session closed for program \(programID)")
    }
    
    private func startSession() {
        status = .initializing
        
        firstly {
            whenProgramDetail
        }.then { program in
            log.info("Content Session started for program \(self.programID)")
            
            // analytics
            self.superPropertyRecorder.register([.programId(id: program.id),
                                                 .programName(name: program.title)])
            self.peoplePropertyRecorder.record([.lastProgramID(programID: program.id),
                                                .lastProgramName(name: program.title)])
            
            self.status = .ready
        }.catch { error in
            self.status = .error
            self.delegate?.session(self, didReceiveError: error)
            
            switch error {
            case NetworkClientError.badRequest:
                log.error("Content Session failed to connect due to a bad request. Please check that the program is ready on the CMS and try again.")
            case NetworkClientError.internalServerError:
                log.error("Content Session failed to connect due to an internal server error. Attempting to retry connection.")
            case let NetworkClientError.invalidResponse(description):
                log.error(description)
            default:
                log.error(error.localizedDescription)
            }
        }
    }
    
    private func teardownSession() {
        // clear the client detail super properties
        superPropertyRecorder.register([.programId(id: ""),
                                        .programName(name: ""),
                                        .league(leagueName: ""),
                                        .sport(sportName: ""),
                                        .pointsThisProgram(points: 0),
                                        .badgeLevelThisProgram(level: 0)])
        sessionDidEnd?()
        if let widgetChannel = self.widgetChannel, let baseProxy = baseWidgetProxy {
            messagingClients?.widgetMessagingClient?.removeListener(baseProxy, fromChannel: widgetChannel)
            baseWidgetProxy = nil
        }
        currentChatRoom?.disconnect()
        currentChatRoom = nil
    }

    @available(*, deprecated, message: "Toggle `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this functionality")
    func pause() {
        pauseWidgets()
    }

    @available(*, deprecated, message: "Toggle `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this functionality")
    func resume() {
        resumeWidgets()
        rankClient?.getUserRank()
    }

    func close() {
        guard sessionIsValid else { return }
        teardownSession()
    }

    func getRewardItems(completion: @escaping (Result<[RewardItem], Error>) -> Void) {
        firstly {
            whenProgramDetail
        }.then {
            completion(.success($0.rewardItems.map { RewardItem(id: $0.id, name: $0.name)}))
        }.catch {
            completion(.failure($0))
        }
    }

    func getPostedWidgets(
        page: WidgetPagination,
        completion: @escaping (Result<[Widget]?, Error>) -> Void
    ) {
        //swiftlint:disable nesting
        struct TimelineURLNotFound: Error { }

        firstly {
            Promises.zip(whenProgramDetail, whenAccessToken)
        }.then { (program, accessToken) -> Promise<(WidgetModelFactory, PaginatedResource<WidgetResource>)> in
            guard let timelineURL: URL = {
                switch page {
                case .first:
                    return program.timelineUrl
                case .next:
                    return self.nextWidgetTimelineUrl
                }
            }() else {
                log.debug("No more posted widgets available")
                throw TimelineURLNotFound()
            }

            return Promises.zip(
                self.whenWidgetModelFactory,
                self.livelikeRestAPIService.getTimeline(timelineURL: timelineURL, accessToken: accessToken)
            )
        }.then { widgetModelFactory, timelineResource in

            self.nextWidgetTimelineUrl = timelineResource.next
            let widgets: [Widget] = timelineResource.results.compactMap { widgetResource in
                do {
                    let widgetModel = try widgetModelFactory.make(from: widgetResource)
                    return DefaultWidgetFactory.makeWidget(from: widgetModel)
                } catch {
                    log.error(error.localizedDescription)
                    return nil
                }
            }
            completion(.success(widgets))
        }.catch { error in
            if error is TimelineURLNotFound {
                completion(.success(nil))
            } else {
                log.debug("Error occured on getting posted widgets: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func getLeaderboardClients(completion: @escaping (Result<[LeaderboardClient], Error>) -> Void) {
        firstly {
            Promises.zip(whenProgramDetail, livelikeIDVendor.whenLiveLikeID)
        }.then { programDetail, livelikeID in
            Promises.all(programDetail.leaderboards.map { leaderboard in
                self.sdkInstance.getLeaderboardAndCurrentEntry(leaderboard: leaderboard, profileID: livelikeID.asString)
            })
        }.then { leaderboardsAndEntries in
            let clients = leaderboardsAndEntries.map {
                LeaderboardClient(
                    leaderboardResource: $0.leaderboard,
                    currentLeaderboardEntry: $0.currentEntry,
                    leaderboardsManager: self.leaderboardsManager
                )
            }
            completion(.success(clients))
        }.catch {
            completion(.failure($0))
        }
    }

    func getPostedWidgetModels(
        page: WidgetPagination,
        completion: @escaping (Result<[WidgetModel]?, Error>) -> Void
    ) {
        //swiftlint:disable nesting
        struct TimelineURLNotFound: Error { }

        firstly {
            Promises.zip(whenProgramDetail, whenAccessToken)
        }.then { (program, accessToken) -> Promise<(WidgetModelFactory, PaginatedResource<WidgetResource>)> in
            guard let timelineURL: URL = {
                switch page {
                case .first:
                    return program.timelineUrl
                case .next:
                    return self.nextWidgetModelTimelineURL
                }
            }() else {
                log.debug("No more posted widgets available")
                throw TimelineURLNotFound()
            }

            return Promises.zip(
                self.whenWidgetModelFactory,
                self.livelikeRestAPIService.getTimeline(timelineURL: timelineURL, accessToken: accessToken)
            )
        }.then { widgetModelFactory, timelineResource in
            self.nextWidgetModelTimelineURL = timelineResource.next
            let widgetModels = try timelineResource.results.map { widgetResource in
                return try widgetModelFactory.make(from: widgetResource)
            }
            completion(.success(widgetModels))
        }.catch { error in
            if error is TimelineURLNotFound {
                completion(.success(nil))
            } else {
                log.debug("Error occured on getting posted widgets: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func getWidgetModel(byID id: String, kind: WidgetKind, completion: @escaping (Result<WidgetModel, Error>) -> Void) {
        firstly {
            Promises.zip(
                self.livelikeRestAPIService.getWidget(id: id, kind: kind),
                self.whenWidgetModelFactory
            )
        }.then { (clientEvent, widgetModelFactory) in
            guard clientEvent.programID == self.programID else {
                throw ContentSessionError.failedToCreateWidgetModelMismatchedProgramID(widgetProgramID: clientEvent.programID, sessionProgramID: self.programID)
            }
            let widgetModel = try widgetModelFactory.make(from: clientEvent)
            completion(.success(widgetModel))
        }.catch { error in
            completion(.failure(error))
        }
    }

    func createWidgetModel(fromJSON jsonObject: Any, completion: @escaping (Result<WidgetModel, Error>) -> Void) {
        firstly {
            self.whenWidgetModelFactory
        }.then { widgetModelFactory in
            let widgetResource = try WidgetPayloadParser.parse(jsonObject)
            guard widgetResource.programID == self.programID else {
                throw ContentSessionError.failedToCreateWidgetModelMismatchedProgramID(widgetProgramID: widgetResource.programID, sessionProgramID: self.programID)
            }
            let widgetModel = try widgetModelFactory.make(from: widgetResource)
            completion(.success(widgetModel))
        }.catch { error in
            completion(.failure(error))
        }
    }
}

// MARK: - Chat
extension InternalContentSession {
    
    /// Updates the image that will represent the user in chat
    func updateUserChatRoomImage(url: URL,
                                 completion: @escaping () -> Void,
                                 failure: @escaping (Error) -> Void) {
        
        firstly {
          whenChatSession
        }.then { chatSession in
            chatSession.avatarURL = url
            completion()
        }.catch { error in
            failure(error)
        }
    }
}

// MARK: - Widgets
extension InternalContentSession: WidgetPauser {
    func setDelegate(_ delegate: PauseDelegate) {
        widgetPauseListeners.addListener(delegate)
    }

    func removeDelegate(_ delegate: PauseDelegate) {
        widgetPauseListeners.removeListener(delegate)
    }

    func pauseWidgets() {
        guard widgetPauseStatus == .unpaused else {
            log.verbose("Widgets are already paused.")
            return
        }
        eventRecorder.record(.widgetPauseStatusChanged(previousStatus: widgetPauseStatus, newStatus: .paused, secondsInPreviousStatus: Date().timeIntervalSince(timeWidgetPauseStatusChanged)))
        
        widgetPauseStatus = .paused
        if let widgetChannel = self.widgetChannel, let baseProxy = baseWidgetProxy {
            messagingClients?.widgetMessagingClient?.removeListener(baseProxy, fromChannel: widgetChannel)
        }
        log.info("Widgets were paused.")
    }

    func resumeWidgets() {
        guard widgetPauseStatus == .paused else {
            log.verbose("Widgets are already unpaused.")
            return
        }
        eventRecorder.record(.widgetPauseStatusChanged(previousStatus: widgetPauseStatus, newStatus: .unpaused, secondsInPreviousStatus: Date().timeIntervalSince(timeWidgetPauseStatusChanged)))
       
        widgetPauseStatus = .unpaused
        if let widgetChannel = self.widgetChannel, let baseProxy = baseWidgetProxy {
            messagingClients?.widgetMessagingClient?.addListener(baseProxy, toChannel: widgetChannel)
        }
        log.info("Widgets have resumed from pause.")
    }
}

// MARK: - PauseDelegate
extension InternalContentSession: PauseDelegate {
    func pauseStatusDidChange(status: PauseStatus) {
        switch status {
        case .paused:
            pauseWidgets()
        case .unpaused:
            resumeWidgets()
        }
    }
}

// MARK: - AwardsProfileDelegate
extension InternalContentSession: AwardsProfileDelegate {
    func awardsProfile(didUpdate awardsProfile: AwardsProfile) {
        superPropertyRecorder.register({
            var props: [SuperProperty] = [
                .pointsThisProgram(points: Int(awardsProfile.totalPoints))
            ]
            
            if let badgeLevelThisProgram = awardsProfile.currentBadge?.level {
                props.append(.badgeLevelThisProgram(level: badgeLevelThisProgram))
            }
            return props
        }())
    }
}
