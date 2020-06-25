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

protocol ContentSessionChatDelegate: AnyObject {
    func chatSession(chatSessionDidChange chatSession: InternalChatSessionProtocol?)
    func chatSession(pauseStatusDidChange pauseStatus: PauseStatus)
}

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

    private var chatPauseStatus: PauseStatus = .unpaused {
        didSet {
            self.chatDelegate?.chatSession(pauseStatusDidChange: chatPauseStatus)
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
    let widgetVotes: WidgetVotes
    var sessionDidEnd: (() -> Void)?
    weak var delegate: ContentSessionDelegate? {
        didSet {
            if delegate != nil {
                initializeDelegatePlayheadTimeSource()
            }
        }
    }
    
    weak var chatDelegate: ContentSessionChatDelegate? {
        didSet {
            if oldValue == nil, currentChatRoom == nil {
                // Assume that this is the first time chatDelegate assigned
                // Automatically join the program chat room
                firstly {
                        self.whenProgramDetail
                }.then { programDetail -> Promise<Void> in
                    guard let chatRoomResource = programDetail.defaultChatRoom else {
                        return Promise(error: ContentSessionError.failedSettingsChatSessionDelegate)
                    }
                    
                    return Promise { [weak self] fulfill, reject in
                        guard let self = self else {
                            reject(ContentSessionError.failedSettingsChatSessionDelegate)
                            return
                        }
                        
                        var chatConfig = ChatSessionConfig(roomID: chatRoomResource.id)
                        chatConfig.syncTimeSource = self.playerTimeSource
                        
                        self.sdkInstance.connectChatRoom(
                            config: chatConfig
                        ) { result in
                            switch result {
                            case .success(let currentChatRoom):
                                DispatchQueue.main.async {
                                    self.chatDelegate?.chatSession(chatSessionDidChange: currentChatRoom as? InternalChatSessionProtocol)
                                    fulfill(())
                                }
                            case .failure(let error):
                                reject(error)
                            }
                        }
                    }
                }.catch {
                    log.error($0.localizedDescription)
                }
            } else {
                self.chatDelegate?.chatSession(chatSessionDidChange: currentChatRoom)
            }
        }
    }

    weak var player: AVPlayer?
    var periodicTimebaseObserver: Any?

    var gamificationManager: GamificationViewManager?
    var rankClient: RankClient?
    private var whenRankClient = Promise<RankClient>()
    private var nextWidgetTimelineUrl: String?

    // Analytics properties

    var eventRecorder: EventRecorder
    private var widgetInteractedEventBuilder: WidgetInteractedEventBuilder?
    private var timeWidgetPauseStatusChanged: Date = Date()
    private var timeChatPauseStatusChanged: Date = Date()
    
    private var sessionIsValid: Bool {
        if status == .ready {
            return true
        }
        delegate?.session(self, didReceiveError: SessionError.invalidSessionStatus(status))
        return false
    }

    private let whenProgramDetail: Promise<ProgramDetail>
    
    private var storeWidgetProxy: StoreWidgetProxy = StoreWidgetProxy()
    
    private(set) lazy var whenWidgetQueue: Promise<WidgetQueue> = {
        firstly {
            Promises.zip(self.whenMessagingClients,
                         self.livelikeIDVendor.whenLiveLikeID,
                         self.whenProgramDetail,
                         self.whenAccessToken)
        }.then { messagingClients, livelikeID, programDetail, accessToken -> Promise<WidgetQueue> in
            
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
                .addProxy { self.storeWidgetProxy }
                .addProxy {
                    let pauseProxy = PauseWidgetProxy(playerTimeSource: self.playerTimeSource,
                                                      initialPauseStatus: self.widgetPauseStatus)
                    self.widgetPauseListeners.addListener(pauseProxy)
                    return pauseProxy
                }
                .addProxy { WriteRewardsURLToRepoProxy(rewardsURLRepo: self.rewardsURLRepo) }
                .addProxy { ImageDownloadProxy() }
                .addProxy { ImpressionProxy(userSessionId: livelikeID.asString, accessToken: accessToken) }
                .addProxy { WidgetLoggerProxy(playerTimeSource: self.playerTimeSource) }
                .addProxy {
                    OnPublishProxy { [weak self] publishData in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.delegate?.widget(self, didBecomeReady: publishData.jsonObject)
                            
                            let widgetFactory = ClientEventWidgetFactory(
                                event: publishData.clientEvent,
                                voteRepo: self.widgetVotes,
                                widgetMessagingOutput: widgetClient,
                                accessToken: accessToken,
                                eventRecorder: self.eventRecorder
                            )
                            if let widgetController = widgetFactory.create(
                                theme: Theme(),
                                widgetConfig: WidgetConfig()
                            ) {
                                self.delegate?.widget(self, didBecomeReady: widgetController)
                            }
                        }
                    }
                }
                .addProxy {
                    WidgetQueue(widgetProcessor: self.storeWidgetProxy,
                                voteRepo: self.widgetVotes,
                                widgetMessagingOutput: widgetClient,
                                accessToken: accessToken,
                                eventRecorder: self.eventRecorder)
                }

            self.widgetPauseListeners.addListener(widgetQueue)
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
    
    var currentChatRoom: InternalChatSessionProtocol? {
        didSet {
            self.chatDelegate?.chatSession(chatSessionDidChange: self.currentChatRoom)
        }
    }

    /// A dictionary of all created rooms
    private var chatRoomsByID: [String: InternalChatSessionProtocol] = [:]
    /// A dictionary of whether a chat room is being created or not - keyed by room id
    private var creatingChatRoomsByID: [String: Promise<InternalChatSessionProtocol>] = [:]

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
                  widgetVotes: WidgetVotes,
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
        self.widgetVotes = widgetVotes
        sdkInstance.setDelegate(self)

        initializeDelegatePlayheadTimeSource()

        initializeMixpanelProperties()
        initializeGamification()
        initializeRankClient()
        initializeWidgetInteractedAnalytics()
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
            self.gamificationManager = GamificationViewManager(storeWidgetProxy: self.storeWidgetProxy,
                                                               widgetRendererDelegator: widgetQueue,
                                                               widgetEventDelegator: widgetQueue,
                                                               rewards: rewards,
                                                               eventRecorder: self.eventRecorder)
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
    
    private func initializeWidgetInteractedAnalytics() {
        firstly {
            Promises.zip(whenWidgetQueue, whenRewards)
        }.then { widgetQueue, rewards in
            let widgetInteractedEventBuilder = WidgetInteractedEventBuilder(eventRecorder: self.eventRecorder,
                                                                            widgetQueue: widgetQueue,
                                                                            rewards: rewards)
            self.widgetInteractedEventBuilder = widgetInteractedEventBuilder
        }.catch { error in
            log.error("Failed to initialize WidgetInteractedEventRecorder with error: \(error.localizedDescription)")
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

    func pause() {
        pauseWidgets()
        pauseChat()
    }

    func resume() {
        resumeChat()
        resumeWidgets()
        rankClient?.getUserRank()
    }

    func close() {
        guard sessionIsValid else { return }
        teardownSession()
    }
    
    func getPostedWidgets(page: WidgetPagination,
                          completion: @escaping (Result<[Widget]?, Error>) -> Void) {
        firstly {
            whenProgramDetail
        }.then { program in
            
            var timelineUrlString: String?
            switch page {
            case .first:
                timelineUrlString = program.timelineUrl
            case .next:
                timelineUrlString = self.nextWidgetTimelineUrl
            }
            
            guard let timelineUrl = timelineUrlString,
                let timelineURL = URL(string: timelineUrl) else {
                    log.debug("No more posted widgets available")
                    completion(.success(nil))
                    return
            }
            
            EngagementSDK.networking.urlSession.dataTask(with: timelineURL) { [weak self] (data, _, error) in
                if let error = error {
                    completion(.failure(error))
                }
                
                guard let data = data else { return }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    guard let dictionary = json as? [String: Any],
                        let jsonWidgets = dictionary["results"] as? [[String: Any]],
                        jsonWidgets.count > 0 else {
                        return completion(.success(nil))
                    }
                       
                    self?.nextWidgetTimelineUrl = dictionary["next"] as? String ?? nil
                    
                    self?.sdkInstance.createWidgets(widgetJSONObjects: jsonWidgets) { result in
                        switch result {
                        case .success(let widgets):
                            completion(.success(widgets))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } catch {
                    log.debug("Error occured on getting posted widgets: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                
            }.resume()
        }
        .catch { error in
            log.debug("Error occured on getting posted widgets: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}

// MARK: - Chat
extension InternalContentSession {

    func pauseChat() {
        guard sessionIsValid else { return }
        guard chatPauseStatus == .unpaused else {
            log.verbose("Chat is already paused.")
            return
        }
        eventRecorder.record(.chatPauseStatusChanged(previousStatus: chatPauseStatus, newStatus: .paused, secondsInPreviousStatus: Date().timeIntervalSince(timeChatPauseStatusChanged)))
        
        chatPauseStatus = .paused
        timeChatPauseStatusChanged = Date()
        self.chatRoomsByID.values.forEach { chatRoomAndQueue in
            chatRoomAndQueue.pause()
        }
        log.info("Chat was paused.")
    }
    
    func resumeChat() {
        guard sessionIsValid else { return }
        guard chatPauseStatus == .paused else {
            log.verbose("Chat is already unpaused.")
            return
        }
        eventRecorder.record(.chatPauseStatusChanged(previousStatus: chatPauseStatus, newStatus: .unpaused, secondsInPreviousStatus: Date().timeIntervalSince(timeChatPauseStatusChanged)))
        
        chatPauseStatus = .unpaused
        timeChatPauseStatusChanged = Date()
        self.chatRoomsByID.values.forEach { chatRoomAndQueue in
            chatRoomAndQueue.resume()
        }
        log.info("Chat has resumed from pause.")
    }

    /// Updates the image that will represent the user in chat
    func updateUserChatRoomImage(url: URL,
                                 completion: @escaping () -> Void,
                                 failure: @escaping (Error) -> Void) {
        firstly {
            whenMessagingClients
        }.then { _ in
            guard let chatClient = self.currentChatRoom else {
                return Promise(error: ContentSessionError.missingChatRoom(placeOfError: "updating user chat room image"))
            }
            return chatClient.updateUserChatImage(url: url)
        }.then {
            completion()
        }.catch {
            failure($0)
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

enum ContentSessionError: LocalizedError {
    case invalidChatRoomURLTemplate
    case invalidChatRoomURL
    case missingChatService
    case missingChatRoomResourceFields
    case failedSettingsChatSessionDelegate
    case failedLoadingInitialChat
    case missingWidgetClient
    case missingSubscribeChannel
    case missingChatRoom(placeOfError: String)

    var errorDescription: String? {
        switch self {
        case .invalidChatRoomURLTemplate:
            return "The template provided to build a chat room url is invalid or incompatible. Expected replaceable string of '{chat_room_id}'."
        case .invalidChatRoomURL:
            return "The chat room resource url is not a valid URL."
        case .missingChatRoomResourceFields:
            return "Failed to initalize Chat because of missing required fields on the chat room resource."
        case .missingChatService:
            return "Failed to initialize Chat because the service is missing."
        case .failedSettingsChatSessionDelegate:
            return "Failed setting the Chat Session Delegate"
        case .missingWidgetClient:
            return "Failed creating Widget Queue due to a missing Widget Client"
        case .missingSubscribeChannel:
            return "Failed creating Widget Queue due to a missing Subscribe Channel"
        case .missingChatRoom(let placeOfError):
            return "Failed \(placeOfError) due to a missing Chat Room"
        case .failedLoadingInitialChat:
            return "Failed loading initial history for chat"
        }
    }
}
