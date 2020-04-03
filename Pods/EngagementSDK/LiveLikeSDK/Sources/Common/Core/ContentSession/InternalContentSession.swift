//
//  InternalContentSession.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dams on 2019-01-18.
//

import AVFoundation
import UIKit

typealias ChatMessagingOutput = ChatRoom & ChatProxyOutput
typealias PlayerTimeSource = (() -> TimeInterval?)
typealias ChatRoomAndQueue = (chatRoom: ChatRoom, chatQueue: ChatQueue)

protocol ChatSessionDelegate: AnyObject {
    func chatSession(chatAdapterDidChange chatAdapter: ChatAdapter?)
    func chatSession(pauseStatusDidChange pauseStatus: PauseStatus)
}

/// Concrete implementation of `ContentSession`
class InternalContentSession: ContentSession {
    struct MessagingClients {
        var userId: String

        /// The `WidgetMessagingClient` to be used for this session
        var widgetMessagingClient: (WidgetClient & SyncMessagingClient)?

        var pubsubService: PubSubService?
    }

    var messagingClients: MessagingClients?
    var widgetChannel: String?
    let syncSessionClient: SyncSessionClient
    let rewardsURLRepo = RewardsURLRepo()

    var status: SessionStatus = .uninitialized {
        didSet {
            delegate?.session?(self, didChangeStatus: status)
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
    private var syncCoordinator: SyncCoordinator?
    private let sdkInstance: EngagementSDK
    private let livelikeIDVendor: LiveLikeIDVendor
    let nicknameVendor: UserNicknameVendor
    private(set) var userPointsVendor: UserPointsVendor
    private let whenAccessToken: Promise<AccessToken>

    let reactionsVendor: ReactionVendor
    let appConfigVendor: ApplicationConfigVendor
    let stickerRepository: StickerRepository
    let reactionsViewModelFactory: ReactionsViewModelFactory
    var widgetVotes = WidgetVotes()
    var sessionDidEnd: (() -> Void)?
    weak var delegate: ContentSessionDelegate? {
        didSet {
            if delegate != nil {
                initializeDelegatePlayheadTimeSource()
            }
        }
    }

    private var currentChatAdapter: ChatAdapter? {
        didSet {
            self.chatDelegate?.chatSession(chatAdapterDidChange: self.currentChatAdapter)
            self.currentChatAdapter?.hideSnapToLive?(true)
        }
    }

    weak var chatDelegate: ChatSessionDelegate? {
        didSet {
            if oldValue == nil, currentChatAdapter == nil {
                // Assume that this is the first time chatDelegate assigned
                // Automatically join the program chat room
                firstly {
                    Promises.zip(self.whenProgramDetail, self.whenMessageReporter)
                }.then { (programDetail, messageReporter) -> Promise<Void> in
                    guard let chatRoomResource = programDetail.defaultChatRoom else { return Promise(error: NilError()) }
                    return self.enterChatRoom(chatRoomResource: chatRoomResource, messageReporter: messageReporter)
                }.catch {
                    log.error($0.localizedDescription)
                }
            }
            self.chatDelegate?.chatSession(chatAdapterDidChange: currentChatAdapter)
        }
    }

    weak var player: AVPlayer?
    var periodicTimebaseObserver: Any?

    var gamificationManager: GamificationViewManager?
    var rankClient: RankClient?
    private var whenRankClient = Promise<RankClient>()

    // Analytics properties

    var eventRecorder: EventRecorder
    private var widgetInteractedEventBuilder: WidgetInteractedEventBuilder?
    private var timeWidgetPauseStatusChanged: Date = Date()
    private var timeChatPauseStatusChanged: Date = Date()
    
    private var installedPlugins: [PluginRoot] = [PluginRoot]()
    private var sessionIsValid: Bool {
        if status == .ready {
            return true
        }
        delegate?.session?(self, didReceiveError: SessionError.invalidSessionStatus(status))
        return false
    }

    private let whenProgramDetail: Promise<ProgramDetail>

    lazy var whenMessageReporter: Promise<MessageReporter> = {
        firstly {
            Promises.zip(whenProgramDetail, whenAccessToken)
        }.then { programDetails, accessToken -> MessageReporter in
            return APIMessageReporter(reportURL: programDetails.reportUrl, accessToken: accessToken)
        }
    }()
    
    private var storeWidgetProxy: StoreWidgetProxy = StoreWidgetProxy()
    
    private(set) lazy var whenWidgetQueue: Promise<WidgetQueue> = {
        firstly {
            Promises.zip(self.whenMessagingClients,
                         self.livelikeIDVendor.whenLiveLikeID,
                         self.whenProgramDetail,
                         self.whenAccessToken)
        }.then { messagingClients, livelikeID, programDetail, accessToken -> Promise<WidgetQueue> in
            
            guard let widgetClient = messagingClients.widgetMessagingClient else {
                return Promise(error: NilError())
            }
            self.createSyncCoordinator(client: widgetClient, syncSessionsUrl: programDetail.syncSessionsUrl, userId: livelikeID.asString)
            
            guard let channel = programDetail.subscribeChannel else {
                return Promise(error: NilError())
            }
            
            self.widgetChannel = channel
            
            let syncWidgetProxy = SynchronizedWidgetProxy(playerTimeSource: self.playerTimeSource)
            self.baseWidgetProxy = syncWidgetProxy
            widgetClient.addListener(syncWidgetProxy, toChannel: channel)
            
            let widgetQueue = syncWidgetProxy
                .addProxy { NoVoteDiscardProxy(voteRepo: self.widgetVotes) }
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
    
    var currentChatRoom: ChatRoom?

    var currentChatRoomID: String? {
        return currentChatRoom?.roomID
    }

    /// A dictionary of all created rooms
    private var chatRoomsByID: [String: ChatRoomAndQueue] = [:]
    /// A dictionary of whether a chat room is being created or not - keyed by room id
    private var creatingChatRoomsByID: [String: Promise<ChatRoomAndQueue>] = [:]

    // MARK: -
    required init(sdkInstance: EngagementSDK,
                  config: SessionConfiguration,
                  whenMessagingClients: Promise<InternalContentSession.MessagingClients>,
                  livelikeIDVendor: LiveLikeIDVendor,
                  nicknameVendor: UserNicknameVendor,
                  userPointsVendor: UserPointsVendor,
                  networkClient: SyncSessionClient,
                  programDetailVendor: ProgramDetailVendor,
                  stickerRepository: StickerRepository,
                  whenAccessToken: Promise<AccessToken>,
                  eventRecorder: EventRecorder,
                  superPropertyRecorder: SuperPropertyRecorder,
                  peoplePropertyRecorder: PeoplePropertyRecorder,
                  reactionVendor: ReactionVendor,
                  appConfigVendor: ApplicationConfigVendor,
                  delegate: ContentSessionDelegate? = nil)
    {
        self.config = config
        self.whenMessagingClients = whenMessagingClients
        self.livelikeIDVendor = livelikeIDVendor
        self.nicknameVendor = nicknameVendor
        self.userPointsVendor = userPointsVendor
        self.delegate = delegate
        programID = config.programID
        syncSessionClient = networkClient
        self.sdkInstance = sdkInstance
        widgetPauseStatus = sdkInstance.widgetPauseStatus
        self.stickerRepository = stickerRepository
        self.whenAccessToken = whenAccessToken
        self.whenProgramDetail = programDetailVendor.getProgramDetails()
        self.eventRecorder = eventRecorder
        self.superPropertyRecorder = superPropertyRecorder
        self.peoplePropertyRecorder = peoplePropertyRecorder
        self.reactionsVendor = reactionVendor
        self.appConfigVendor = appConfigVendor
        self.reactionsViewModelFactory = ReactionsViewModelFactory(reactionAssetsVendor: reactionVendor, cache: Cache.shared)
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
        
        stickerRepository.retrieve(programID: programID)
    }
    
    private func initializeDelegatePlayheadTimeSource() {
        playerTimeSource = { [weak self] in
            if
                let self = self,
                let delegate = self.delegate
            {
                return delegate.playheadTimeSource?(self)?.timeIntervalSince1970
            }
            return nil
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
            self.delegate?.session?(self, didReceiveError: error)
            
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
        syncCoordinator?.teardown()
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

    func install(plugin: Plugin) {
        let pluginName = String(describing: type(of: plugin))

        if let resolvablePlugin = plugin as? ResolveablePlugin {
            log.info("Installing plugin: \(pluginName)")
            whenWidgetQueue.then { widgetQueue in
                let deps: [String: Any] = [
                    String(describing: WidgetRenderer.self): widgetQueue,
                    String(describing: WidgetPauser.self): WeakWidgetPauser(self),
                    String(describing: WidgetCrossSessionPauser.self): self.sdkInstance,
                    String(describing: EventRecorder.self): self.eventRecorder
                ]
                guard let pluginRoot = resolvablePlugin.resolve(deps) else {
                    return
                }
                self.installedPlugins.append(pluginRoot)

                log.info("Finished installing plugin: \(pluginName)")
            }.catch {
                log.error($0.localizedDescription)
            }
        }
    }

    func startSyncSession() {
        guard sessionIsValid else { return }
        syncCoordinator?.startSyncingSession(playerTimeSource: playerTimeSource)
    }

    private func createSyncCoordinator(client: SyncMessagingClient, syncSessionsUrl: URL, userId: String) {
        syncCoordinator = SyncCoordinator(
            syncSessionClient: syncSessionClient,
            syncMessagingClient: client,
            syncSessionsUrl: syncSessionsUrl,
            userSessionId: userId
        )
    }
}

// MARK: - Chat
extension InternalContentSession {
    /**
     Send a message on the specified channel.
     */
    func sendChatMessage(_ message: ChatInputMessage) -> Promise<ChatMessageID>? {
        guard sessionIsValid else { return nil }

        let clientMessage = ClientMessage(message: message.message,
                                          timeStamp: playerTimeSource?(),
                                          badge: whenRewards.value?.lastEarnedBadge,
                                          reactions: .empty,
                                          imageURL: message.imageURL,
                                          imageSize: message.imageSize)
        return self.currentChatRoom?.sendMessage(clientMessage)
    }
    
    func deleteMessage(messageID: ChatMessageID, message: String) {
        guard sessionIsValid else { return  }
        let clientMessage = ClientMessage(message: "",
                                          timeStamp: nil,
                                          badge: whenRewards.value?.lastEarnedBadge,
                                          reactions: .empty,
                                          imageURL: nil,
                                          imageSize: nil)
        self.currentChatRoom?.deleteMessage(clientMessage, messageID: messageID.asString)
    }

    func sendReaction(
        messageID: ChatMessageID,
        _ reaction: ReactionID,
        reactionToRemove: ReactionVote.ID?
    ) -> Promise<Void> {
        guard let chatClient = self.currentChatRoom else { return Promise(error: NilError()) }
        return firstly {
            chatClient.sendMessageReaction(
                messageID,
                reaction: reaction,
                reactionsToRemove: reactionToRemove
            )
        }.then {
            log.verbose("Successfully sent reaction to chat message with id: \(messageID.asString)")
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func removeReactions(
        _ reaction: ReactionVote.ID,
        fromMessageWithID messageID: ChatMessageID
    ) -> Promise<Void> {
        guard let chatClient = self.currentChatRoom else { return Promise(error: NilError()) }
        return firstly {
            chatClient.removeMessageReactions(
                reaction: reaction,
                fromMessageWithID: messageID
            )
        }.then {
            log.verbose("Successfully removed reaction from chat message with id: \(messageID.asString)")
        }.catch {
            log.error($0.localizedDescription)
        }
    }
    
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
            chatRoomAndQueue.chatRoom.pause()
        }
        self.currentChatAdapter?.didInteractWithMessageView = false // reset user interaction when paused
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
            chatRoomAndQueue.chatRoom.resume()
        }
        log.info("Chat has resumed from pause.")
    }
    
    public func enterChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // Using nil reporter here because group chat does not support reporting
        firstly {
            self.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource in
            self.enterChatRoom(chatRoomResource: chatRoomResource, messageReporter: nil)
        }.then {
            completion()
        }.catch {
            log.error($0.localizedDescription)
            failure($0)
        }
    }

    private func enterChatRoom(chatRoomResource: ChatRoomResource, messageReporter: MessageReporter?) -> Promise<Void> {
        return firstly {
            Promises.zip(
                self.livelikeIDVendor.whenLiveLikeID,
                self.createChatRoom(chatRoomResource: chatRoomResource)
            )
        }.then { livelikeID, chatQueueAndRoom in
            self.currentChatRoom = chatQueueAndRoom.chatRoom

            let factory = MessageViewModelFactory(
                stickerRepository: self.stickerRepository,
                channel: "",
                reactionsFactory: self.reactionsViewModelFactory,
                messageReporter: messageReporter
            )

            let adapter = ChatAdapter(queue: chatQueueAndRoom.chatQueue,
                                      userID: ChatUser.ID(idString: livelikeID.asString),
                                      messageReporter: messageReporter,
                                      messageViewModelFactory: factory,
                                      eventRecorder: self.eventRecorder)
            self.currentChatAdapter = adapter
        }.asVoid()
    }

    private func getChatRoomResource(roomID: String) -> Promise<ChatRoomResource> {
        return firstly {
            self.appConfigVendor.whenApplicationConfig
        }.then { (appConfig: ApplicationConfiguration) in
            let stringToReplace = "{chat_room_id}"
            guard appConfig.chatRoomDetailUrlTemplate.contains(stringToReplace) else {
                return Promise(error: ContentSessionError.invalidChatRoomURLTemplate)
            }
            let urlTemplateFilled = appConfig.chatRoomDetailUrlTemplate.replacingOccurrences(of: stringToReplace, with: roomID)
            guard let chatRoomURL = URL(string: urlTemplateFilled) else {
                return Promise(error: ContentSessionError.invalidChatRoomURL)
            }
            let resource = Resource<ChatRoomResource>(get: chatRoomURL)
            return EngagementSDK.networking.load(resource)
        }
    }

    func joinChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        firstly {
            self.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource in
            self.createChatRoom(chatRoomResource: chatRoomResource)
        }.then { _ in
            completion()
        }.catch {
            log.error($0.localizedDescription)
            failure($0)
        }
    }

    func leaveChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let chatRoom = chatRoomsByID[roomID] {
            chatRoom.chatRoom.disconnect()
            completion()
        }
        failure(NilError())
    }

    func getLatestChatMessages(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping ([ChatMessage]) -> Void,
        failure: @escaping (Error) -> Void) {

        firstly {
            Promises.zip(
                whenMessagingClients,
                getChatRoomResource(roomID: roomID),
                livelikeIDVendor.whenLiveLikeID
            )
        }.then { messagingClients, chatRoomResource, livelikeID in
            guard let pubsubService = messagingClients.pubsubService else { return }
            guard let pubsubChatChannel = chatRoomResource.channels.chat.pubnub else { return }

            let userID = ChatUser.ID(idString: livelikeID.asString)

            pubsubService.fetchHistory(
                channel: pubsubChatChannel,
                oldestMessageDate: timestamp,
                newestMessageDate: nil,
                limit: 100
            ) { result in
                switch result {
                case let .success(historyResult):
                    var deletedMessageIDs = Set<ChatMessageID>()
                    let processedHistory: [ChatMessageType] = historyResult.messages.compactMap { message in
                        guard let payload = try? PubSubChatMessageDecoder.shared.decode(dict: message.message) else {
                            assertionFailure()
                            return nil
                        }

                        switch payload {
                        case .messageCreated(let payload):
                            return ChatMessageType(
                                from: payload,
                                channel: pubsubChatChannel,
                                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                                actions: message.messageActions,
                                userID: userID
                            )
                        case .messageDeleted(let payload):
                            deletedMessageIDs.insert(ChatMessageID(payload.id))
                            return nil
                        case .messageUpdated(_):
                            return nil
                        case .imageCreated(let payload):
                            return ChatMessageType(
                                from: payload,
                                channel: pubsubChatChannel,
                                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                                actions: message.messageActions,
                                userID: userID
                            )
                        case .imageDeleted(let payload):
                            deletedMessageIDs.insert(ChatMessageID(payload.id))
                            return nil
                        }
                    }

                    let messagesToBeShown = processedHistory.filter { !deletedMessageIDs.contains($0.id) }

                    let chatMessages = messagesToBeShown.map { chatMessage in
                        return ChatMessage(
                            senderUsername: chatMessage.nickname,
                            message: chatMessage.message,
                            timestamp: chatMessage.timestamp
                        )
                    }
                    completion(chatMessages)
                case let .failure(error):
                    failure(error)
                }
            }
        }.catch {
            log.error($0.localizedDescription)
            failure($0)
        }
    }

    /// Factory method for a ChatMessageType
    private func chatMessageType(
        from chatPubnubMessage: PubSubChatMessage,
        channel: String,
        timetoken: TimeToken,
        id: ChatMessageID,
        actions: [PubSubMessageAction],
        userID: ChatUser.ID
    ) -> ChatMessageType {
        let senderID = ChatUser.ID(idString: chatPubnubMessage.payload.senderId ?? "deleted_\(chatPubnubMessage.payload.id)")
        let chatUser = ChatUser(
            userId: senderID,
            isActive: false,
            isLocalUser: senderID == userID,
            nickName: chatPubnubMessage.payload.senderNickname ?? "deleted_\(chatPubnubMessage.payload.id)",
            friendDiscoveryKey: nil,
            friendName: nil,
            badgeImageURL: chatPubnubMessage.payload.badgeImageUrl
        )

        let reactions: ReactionVotes = {
            var allVotes: [ReactionVote] = []

            actions.forEach { action in
                guard action.type == MessageActionType.reactionCreated.rawValue else { return }
                let voteID = ReactionVote.ID(action.id)
                let reactionID = ReactionID(fromString: action.value)
                let reaction = ReactionVote(
                    voteID: voteID,
                    reactionID: reactionID,
                    isMine: action.sender == userID.asString
                )
                allVotes.append(reaction)
            }
            return ReactionVotes(allVotes: allVotes)
        }()

        let message = ChatMessageType(
            id: id,
            roomID: channel,
            message: chatPubnubMessage.payload.message ?? "deleted_\(chatPubnubMessage.payload.id)",
            sender: chatUser,
            videoTimestamp: chatPubnubMessage.payload.programDateTime?.timeIntervalSince1970,
            reactions: reactions,
            timestamp: timetoken.date,
            profileImageUrl: chatPubnubMessage.payload.senderImageUrl,
            createdAt: timetoken,
            bodyImageUrl: nil,
            bodyImageSize: nil
        )

        return message
    }

    func getChatMessageCount(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping (Int) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        self.getLatestChatMessages(
            forRoom: roomID,
            since: timestamp,
            completion: { messages in
                completion(messages.count)
            },
            failure: failure
        )
    }

    /// Updates the image that will represent the user in chat
    func updateUserChatRoomImage(url: URL,
                                 completion: @escaping () -> Void,
                                 failure: @escaping (Error) -> Void) {
        firstly {
            whenMessagingClients
        }.then { _ in
            guard let chatClient = self.currentChatRoom else {
                return Promise(error: NilError())
            }
            return chatClient.updateUserChatImage(url: url)
        }.then {
            completion()
        }.catch {
            failure($0)
        }
    }

    private func createChatRoom(chatRoomResource: ChatRoomResource) -> Promise<ChatRoomAndQueue> {
        if let chatRoomAndQueue = chatRoomsByID[chatRoomResource.id] {
            return Promise(value: chatRoomAndQueue)
        }
        
        if let chatRoomAndQueueCreatingPromise = creatingChatRoomsByID[chatRoomResource.id] {
            return chatRoomAndQueueCreatingPromise
        }

        let whenChatRoomCreated: Promise<ChatRoomAndQueue> = firstly {
            Promises.zip(
                self.whenMessagingClients,
                self.livelikeIDVendor.whenLiveLikeID,
                self.reactionsVendor.getReactions(),
                self.nicknameVendor.whenInitialNickname
            )
        }.then { (messagingClients, livelikeID, availableReactions, nickname) in

            let reactionChannel: PubSubChannel? = {
                guard let reactionChannel = chatRoomResource.channels.reactions?.pubnub else { return nil }
                return messagingClients.pubsubService?.subscribe(reactionChannel)
            }()

            guard let chatPubnubChannel = chatRoomResource.channels.chat.pubnub else {
                return Promise(error: ContentSessionError.missingChatRoomResourceFields)
            }
            guard let chatChannel = messagingClients.pubsubService?.subscribe(chatPubnubChannel) else {
                return Promise(error: ContentSessionError.missingChatService )
            }

            let imageUploader = ImageUploader(
                uploadUrl: chatRoomResource.uploadUrl,
                urlSession: EngagementSDK.networking.urlSession
            )

            let chatRoom = PubSubChatRoom(
                roomID: chatRoomResource.id,
                chatChannel: chatChannel,
                reactionChannel: reactionChannel,
                userID: ChatUser.ID(idString: livelikeID.asString),
                nickname: self.nicknameVendor,
                imageUploader: imageUploader
            )
            chatRoom.availableReactions = availableReactions.map({ $0.id })

            let chatID = ChatUser.ID(idString: livelikeID.asString)
            let chatQueue = chatRoom
                .addProxy { SynchronizedChatProxy(playerTimeSource: self.playerTimeSource) }
                .addProxy { ChatIntegratorHookProxy(delegate: self.delegate, session: self) }
                .addProxy { ChatLoggerProxy(playerTimeSource: self.playerTimeSource) }
                .addProxy { ChatQueue(userID: chatID) }

            let chatRoomAndQueue: ChatRoomAndQueue = (chatRoom: chatRoom, chatQueue: chatQueue)
            self.chatRoomsByID[chatRoomResource.id] = chatRoomAndQueue

            return Promise(value: chatRoomAndQueue)
        }
        
        self.creatingChatRoomsByID[chatRoomResource.id] = whenChatRoomCreated
        return whenChatRoomCreated
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
        }
    }
}
