//
//  PubSubChatRoom.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/19/19.
//

import UIKit

class PubSubChatRoom: NSObject, InternalChatSessionProtocol {
   
    public var messages: [ChatMessage] = []

    let isAvatarDisplayed: Bool
    var stickerRepository: StickerRepository
    var recentlyUsedStickers: LimitedArray<Sticker> = LimitedArray<Sticker>(maxSize: 30)
    var isReportingEnabled: Bool {
        return messageReporter != nil
    }
    var avatarURL: URL?
    
    let blockList: BlockList
    let eventRecorder: EventRecorder
    let superPropertyRecorder: SuperPropertyRecorder
    let peoplePropertyRecorder: PeoplePropertyRecorder
    let reactionsVendor: ReactionVendor
    
    private let messageHistoryLimit: UInt
    private var chatChannel: PubSubChannel
    private let userID: ChatUser.ID
    private let nickname: UserNicknameVendor
    private let _roomID: String
    private let _title: String?
    private var oldestChatMessageTimetoken: TimeToken?
    // where deleted message id's are stored
    private var deletedMessageIDs: Set<ChatMessageID> = Set()
    private var imageUploader: ImageUploader
    private var chatMessages: [PubSubID: ChatMessage] = [:]
    // maps ChatMessageIDs to PubSubIDs
    private var chatMessageIDsToPubSubIDs: [ChatMessageID: PubSubID] = [:]
    private let messageReporter: MessageReporter?
    private let chatFilters: Set<ChatFilter>
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository
    private var publicDelegates: Listener<ChatSessionDelegate> = Listener()
    private var delegates: Listener<InternalChatSessionDelegate> = Listener()
    private var isLoadingHistory: Bool = false

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601Full)
        return encoder
    }()
    
    init(
        roomID: String,
        chatChannel: PubSubChannel,
        userID: ChatUser.ID,
        nickname: UserNicknameVendor,
        imageUploader: ImageUploader,
        analytics: AnalyticsProtocol,
        reactionsVendor: ReactionVendor,
        messageHistoryLimit: UInt,
        messageReporter: MessageReporter?,
        title: String?,
        chatFilters: Set<ChatFilter>,
        stickerRepository: StickerRepository,
        shouldDisplayAvatar: Bool
    ) {
        self._roomID = roomID
        self.chatChannel = chatChannel
        self.userID = userID
        self.nickname = nickname
        self.imageUploader = imageUploader
        self.blockList = BlockList(for: userID)
        self.eventRecorder = analytics
        self.superPropertyRecorder = analytics
        self.peoplePropertyRecorder = analytics
        self.reactionsVendor = reactionsVendor
        self.messageHistoryLimit = messageHistoryLimit
        self.messageReporter = messageReporter
        self._title = title
        self.chatFilters = chatFilters
        self.stickerRepository = stickerRepository
        self.isAvatarDisplayed = shouldDisplayAvatar
        super.init()

        self.chatChannel.delegate = self
    }
    
    deinit {
        log.info("Chat Session for room \(roomID) has ended.")
    }
}

// MARK: - Private methods

private extension PubSubChatRoom {
    
    private func sendMessage(
        chatMessage: NewChatMessage,
        messageID: String,
        messageEvent: PubSubChatEvent,
        completion: @escaping (Result<ChatMessageID, Error>) -> Void
    ){
        guard let nickname = nickname.currentNickname else {
            return completion(.failure(PubSubChatRoomError.sendMessageFailedNoNickname))
        }

        let pdt: Date? = {
            if let timeStamp = chatMessage.timeStamp {
                return Date.init(timeIntervalSince1970: timeStamp)
            }
            return nil
        }()
        
        // Build a Mock Message
        let chatUser = ChatUser(
            userId: self.userID,
            isActive: false,
            isLocalUser: true,
            nickName: nickname,
            friendDiscoveryKey: nil,
            friendName: nil
        )
        let chatMessageID = ChatMessageID(messageID)
        var mockMessage: ChatMessage {
            if let imageURL = chatMessage.imageURL, let imageSize = chatMessage.imageSize {
                return ChatMessage(
                    id: chatMessageID,
                    roomID: self.roomID,
                    message: "",
                    sender: chatUser,
                    videoTimestamp: chatMessage.timeStamp,
                    reactions: ReactionVotes(allVotes: []),
                    timestamp: Date(),
                    profileImageUrl: self.avatarURL,
                    createdAt: TimeToken(pubnubTimetoken: 0),
                    bodyImageUrl: imageURL,
                    bodyImageSize: CGSize(
                        width: Int(imageSize.width),
                        height: Int(imageSize.width)),
                    filteredMessage: nil,
                    filteredReasons: Set()
                )
            } else  {
                return ChatMessage(
                    id: chatMessageID,
                    roomID: self.roomID,
                    message: chatMessage.text ?? "",
                    sender: chatUser,
                    videoTimestamp: chatMessage.timeStamp,
                    reactions: ReactionVotes(allVotes: []),
                    timestamp: Date(),
                    profileImageUrl: self.avatarURL,
                    createdAt: TimeToken(pubnubTimetoken: 0),
                    bodyImageUrl: nil,
                    bodyImageSize: nil,
                    filteredMessage: nil,
                    filteredReasons: Set()
                )
            }
        }
        
        self.messages.append(mockMessage)
        self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage )}
        self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage) }
        
        // Build and Send a real message payload
        if let imageURL = chatMessage.imageURL, let imageSize = chatMessage.imageSize {
            self.mediaRepository.getImage(url: imageURL) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let success):
                    // upload image
                    self.imageUploader.upload(success.imageData) { [weak self] result in
                        switch result {
                        case .success(let imageResource):
                            guard let self = self else { return }
                            let payload = PubSubImagePayload(
                                id: messageID,
                                imageUrl: imageResource.imageUrl,
                                imageHeight: Int(imageSize.height),
                                imageWidth: Int(imageSize.width),
                                senderId: self.userID.asString,
                                senderNickname: nickname,
                                senderImageUrl: self.avatarURL,
                                programDateTime: pdt
                            )
                            let message = PubSubChatImage(
                                event: .imageCreated,
                                payload: payload
                            )
                            
                            self.sendMessageToChatChannel(payloadMessage: message,
                                                          mockMessage: mockMessage,
                                                          completion: completion)
                            
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } else if let message = chatMessage.text {
            let payload = PubSubChatPayload(
                id: messageID,
                message: message,
                senderId: userID.asString,
                senderNickname: nickname,
                senderImageUrl: avatarURL,
                programDateTime: pdt,
                filteredMessage: nil,
                contentFilter: nil
            )

            let pubnubChatMessage = PubSubChatMessage(event: messageEvent, payload: payload)
            sendMessageToChatChannel(payloadMessage: pubnubChatMessage,
                                     mockMessage: mockMessage,
                                     completion: completion)
        }
    }
    
    private func sendMessageToChatChannel<T: Encodable>(
        payloadMessage: T,
        mockMessage: ChatMessage,
        completion: @escaping (Result<ChatMessageID, Error>) -> Void
    ) {
        
        guard let encodedMessage = try? self.encoder.encode(payloadMessage) else {
            completion(.failure(PubSubChatRoomError.failedToEncodeChatMessage))
            return
        }
        guard let encodedMessageString = String(data: encodedMessage, encoding: .utf8) else {
            completion(.failure(PubSubChatRoomError.failedToEncodeChatMessage))
            return
        }

        self.chatChannel.send(encodedMessageString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let pubsubID):
                self.chatMessageIDsToPubSubIDs[mockMessage.messageID] = pubsubID
                mockMessage.messageID = ChatMessageID(pubsubID)
                self.chatMessages[pubsubID] = mockMessage
                
                completion(.success(ChatMessageID(pubsubID)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// The main function from which PubNub messages are sent out
    /// - Parameters:
    ///   - clientMessage: chat message
    ///   - messageID: chat message identifier
    ///   - messageEvent: the type of message to be sent
    func sendMessage(_ clientMessage: ClientMessage,
                     messageID: String,
                     messageEvent: PubSubChatEvent) -> Promise<ChatMessageID> {

        guard let nickname = nickname.currentNickname else {
            return Promise(error: PubSubChatRoomError.sendMessageFailedNoNickname)
        }

        let pdt: Date? = {
            if let timeStamp = clientMessage.timeStamp {
                return Date.init(timeIntervalSince1970: timeStamp)
            }
            return nil
        }()

        if let imageURL = clientMessage.imageURL, let imageSize = clientMessage.imageSize {
            return Promise { [weak self] fulfill, reject in
                guard let self = self else { return }
                guard let nickname = self.nickname.currentNickname else { return }

                // Send mock message

                let chatUser = ChatUser(
                    userId: self.userID,
                    isActive: false,
                    isLocalUser: true,
                    nickName: nickname,
                    friendDiscoveryKey: nil,
                    friendName: nil
                )
                let chatMessageID = ChatMessageID(messageID)
                let mockMessage = ChatMessage(
                    id: chatMessageID,
                    roomID: self.roomID,
                    message: "",
                    sender: chatUser,
                    videoTimestamp: clientMessage.timeStamp,
                    reactions: ReactionVotes(allVotes: []),
                    timestamp: Date(),
                    profileImageUrl: self.avatarURL,
                    createdAt: TimeToken(pubnubTimetoken: 0),
                    bodyImageUrl: imageURL,
                    bodyImageSize: CGSize(
                        width: Int(imageSize.width),
                        height: Int(imageSize.width)),
                    filteredMessage: nil,
                    filteredReasons: Set()
                )
                self.messages.append(mockMessage)
                self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage )}
                self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage) }

                // Send real message
                self.mediaRepository.getImage(url: imageURL) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let success):
                        // upload image
                        self.imageUploader.upload(success.imageData) { [weak self] result in
                            switch result {
                            case .success(let imageResource):
                                //publish mock message
                                guard let self = self else { return }
                                let payload = PubSubImagePayload(
                                    id: messageID,
                                    imageUrl: imageResource.imageUrl,
                                    imageHeight: Int(imageSize.height),
                                    imageWidth: Int(imageSize.width),
                                    senderId: self.userID.asString,
                                    senderNickname: nickname,
                                    senderImageUrl: self.avatarURL,
                                    programDateTime: pdt
                                )
                                let message = PubSubChatImage(
                                    event: .imageCreated,
                                    payload: payload
                                )
                                guard let encodedMessage = try? self.encoder.encode(message) else {
                                    return reject(PubSubChatRoomError.failedToEncodeChatMessage)
                                }
                                guard let encodedMessageString = String(data: encodedMessage, encoding: .utf8) else {
                                    return reject(PubSubChatRoomError.failedToEncodeChatMessage)
                                }

                                self.chatChannel.send(encodedMessageString) { [weak self] result in
                                    guard let self = self else { return }
                                    switch result {
                                    case .success(let pubsubID):
                                        self.chatMessageIDsToPubSubIDs[chatMessageID] = pubsubID
                                        mockMessage.messageID = ChatMessageID(pubsubID)
                                        self.chatMessages[pubsubID] = mockMessage
                                        fulfill(chatMessageID)
                                    case .failure(let error):
                                        reject(error)
                                    }
                                }
                            case .failure(let error):
                                reject(error)
                            }
                        }
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        } else if let message = clientMessage.message {
            let payload = PubSubChatPayload(
                id: messageID,
                message: message,
                senderId: userID.asString,
                senderNickname: nickname,
                senderImageUrl: avatarURL,
                programDateTime: pdt,
                filteredMessage: nil,
                contentFilter: nil
            )

            return Promise { [weak self] fulfill, reject in
                guard let self = self else { return }
                let pubnubChatMessage = PubSubChatMessage(event: messageEvent, payload: payload)
                let encodedMessage = try self.encoder.encode(pubnubChatMessage)
                guard let encodedMessageString = String(data: encodedMessage, encoding: .utf8) else {
                    throw PubSubChatRoomError.failedToEncodeChatMessage
                }
                self.chatChannel.send(encodedMessageString) { result in
                    switch result {
                    case .success(let pubsubID):
                        fulfill(ChatMessageID(pubsubID))
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        }
        return Promise()
    }

    /// Processes the chatChannel messages from history
    /// - Filters out deleted messages
    private func processMessagesFromChatHistory(historyResult: PubSubHistoryResult) -> [ChatMessage] {
        let unfilteredMessages: [ChatMessage] = historyResult.messages.compactMap { message in
            do {
                let payload = try PubSubChatMessageDecoder.shared.decode(dict: message.message)
                
                switch payload {
                case .messageCreated(let payload):
                    // Exclude filtered messages
                    guard payload.filteredSet.isDisjoint(with: self.chatFilters) else {
                        return nil
                    }
                    let chatMessageType = ChatMessage(
                        from: payload,
                        chatRoomID: self.roomID,
                        channel: self.chatChannel.name,
                        timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                        actions: message.messageActions,
                        userID: self.userID
                    )
                    self.chatMessageIDsToPubSubIDs[chatMessageType.messageID] = message.pubsubID
                    return chatMessageType
                case .messageDeleted(let payload):
                    let id = ChatMessageID(payload.id)
                    deletedMessageIDs.insert(id)
                    return nil
                case .imageCreated(let payload):
                    let chatMessageType = ChatMessage(
                        from: payload,
                        chatRoomID: self.roomID,
                        channel: self.chatChannel.name,
                        timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                        actions: message.messageActions,
                        userID: self.userID
                    )

                    self.chatMessageIDsToPubSubIDs[chatMessageType.messageID] = message.pubsubID
                    return chatMessageType
                case .imageDeleted(let payload):
                    let id = ChatMessageID(payload.id)
                    deletedMessageIDs.insert(id)
                    return nil
                }
            } catch {
                log.error("Decode error for message \(message.message) \n\(error.localizedDescription)")
                return nil
            }
        }

        let messagesToBeShown = unfilteredMessages.filter { !deletedMessageIDs.contains($0.messageID) }
        return messagesToBeShown
    }
}

// MARK: - PubSubChannelDelegate

extension PubSubChatRoom: PubSubChannelDelegate {
    
    func channel(_ channel: PubSubChannel, messageCreated message: PubSubChannelMessage) {
        guard let payload = try? PubSubChatMessageDecoder.shared.decode(dict: message.message) else {
            log.error("Failed to decode pub sub chat message.")
            return
        }

        switch payload {
        case .messageCreated(let payload):
            let chatMessage = ChatMessage(
                from: payload,
                chatRoomID: self.roomID,
                channel: roomID,
                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                actions: message.messageActions,
                userID: userID
            )
            chatMessages[message.pubsubID] = chatMessage
            if self.chatMessageIDsToPubSubIDs[chatMessage.messageID] == nil {
                // only publish downstream here if pubsub id doesn't exist yet
                // if pubsub id already exists then this message was mocked and published earlier
                self.chatMessageIDsToPubSubIDs[chatMessage.messageID] = message.pubsubID
                self.messages.append(chatMessage)
                self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
                self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
            }
        case .messageDeleted(let payload):
            let chatMessageID = ChatMessageID(payload.id)
            self.delegates.publish { $0.chatSession(self, didRecieveMessageDeleted: chatMessageID)}
            deletedMessageIDs.insert(chatMessageID)
            chatMessages.removeValue(forKey: message.pubsubID)
        case .imageCreated(let payload):
            let chatMessage = ChatMessage(
                from: payload,
                chatRoomID: self.roomID,
                channel: roomID,
                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                actions: message.messageActions,
                userID: userID
            )
            
            // always update the mock image `ChatMessage` with the real one from Pubnub
            chatMessages[message.pubsubID] = chatMessage

            if self.chatMessageIDsToPubSubIDs[chatMessage.messageID] == nil {
                // only publish downstream here if pubsub id doesn't exist yet
                // if pubsub id already exists then this message was mocked and published earlier
                self.chatMessageIDsToPubSubIDs[chatMessage.messageID] = message.pubsubID
                self.messages.append(chatMessage)
                self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
                self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
            }
        case .imageDeleted(let payload):
            let chatMessageID = ChatMessageID(payload.id)
            self.delegates.publish { $0.chatSession(self, didRecieveMessageDeleted: chatMessageID)}
            deletedMessageIDs.insert(chatMessageID)
            chatMessages.removeValue(forKey: message.pubsubID)
        }
    }

    func channel(_ channel: PubSubChannel, messageActionCreated messageAction: PubSubMessageAction) {
        guard let chatMessageType = self.chatMessages[messageAction.messageID] else {
            log.error(PubSubChatRoomError.failedToFindChatMessageForPubSubID(pubsubID: messageAction.messageID))
            return
        }
        let voteID = ReactionVote.ID(messageAction.id)
        let reactionID = ReactionID(fromString: messageAction.value)
        let reactionVote = ReactionVote(
            voteID: voteID,
            reactionID: reactionID,
            isMine: self.userID.asString == messageAction.sender
        )
        chatMessageType.reactions.allVotes.append(reactionVote)
        self.chatMessages[messageAction.messageID] = chatMessageType
        self.delegates.publish { $0.chatSession(self, didRecieveMessageUpdate: chatMessageType)}
    }

    func channel(_ channel: PubSubChannel, messageActionDeleted messageActionID: PubSubID, messageID: PubSubID) {
        guard let chatMessageType = self.chatMessages[messageID] else {
            log.error(PubSubChatRoomError.failedToFindChatMessageForPubSubID(pubsubID: messageID))
            return
        }
        let voteID = ReactionVote.ID(messageActionID)
        chatMessageType.reactions.allVotes.removeAll(where: { $0.voteID == voteID })
        self.chatMessages[messageID] = chatMessageType
        self.delegates.publish { $0.chatSession(self, didRecieveMessageUpdate: chatMessageType)}
    }
}

// MARK: - ChatMessagingOutput

extension PubSubChatRoom {

    func addDelegate(_ delegate: ChatSessionDelegate) {
        publicDelegates.addListener(delegate)
    }
    
    func removeDelegate(_ delegate: ChatSessionDelegate) {
        publicDelegates.removeListener(delegate)
    }
    
    func addInternalDelegate(_ delegate: InternalChatSessionDelegate) {
        delegates.addListener(delegate)
    }
    
    func removeInternalDelegate(_ delegate: InternalChatSessionDelegate) {
        delegates.removeListener(delegate)
    }
    
    var roomID: String {
        return _roomID
    }
    
    var title: String? {
        return _title
    }
    
    func getMessages(since timestamp: TimeToken, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        self.chatChannel.fetchMessages(
            since: timestamp,
            limit: 100
        ) { result in
            switch result {
            case let .success(historyResult):
                var deletedMessageIDs = Set<ChatMessageID>()
                let processedHistory: [ChatMessage] = historyResult.messages.compactMap { message in
                    guard let payload = try? PubSubChatMessageDecoder.shared.decode(dict: message.message) else {
                        assertionFailure()
                        return nil
                    }

                    switch payload {
                    case .messageCreated(let payload):
                        // Exclude filtered messages
                        guard payload.filteredSet.isDisjoint(with: self.chatFilters) else {
                            return nil
                        }
                        return ChatMessage(
                            from: payload,
                            chatRoomID: self.roomID,
                            channel: self.chatChannel.name,
                            timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                            actions: message.messageActions,
                            userID: self.userID
                        )
                    case .messageDeleted(let payload):
                        deletedMessageIDs.insert(ChatMessageID(payload.id))
                        return nil
                    case .imageCreated(let payload):
                        return ChatMessage(
                            from: payload,
                            chatRoomID: self.roomID,
                            channel: self.chatChannel.name,
                            timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                            actions: message.messageActions,
                            userID: self.userID
                        )
                    case .imageDeleted(let payload):
                        deletedMessageIDs.insert(ChatMessageID(payload.id))
                        return nil
                    }
                }

                let messagesToBeShown = processedHistory.filter { !deletedMessageIDs.contains($0.messageID) }
                completion(.success(messagesToBeShown))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func getMessageCount(since timestamp: TimeToken, completion: @escaping (Result<Int, Error>) -> Void) {
        self.chatChannel.fetchMessages(
            since: timestamp,
            limit: 100
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let historyResult):
                // Filter out deleted messages because message count should only count existing messages
                let filteredMessages = self.filterDeletedMessages(historyResult: historyResult)
                completion(.success(filteredMessages.count))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func filterDeletedMessages(historyResult: PubSubHistoryResult) -> [ChatMessage] {
        var deletedMessageIDs = Set<ChatMessageID>()
        let processedHistory: [ChatMessage] = historyResult.messages.compactMap { message in
            guard let payload = try? PubSubChatMessageDecoder.shared.decode(dict: message.message) else {
                assertionFailure()
                return nil
            }

            switch payload {
            case .messageCreated(let payload):
                // Exclude filtered messages
                guard payload.filteredSet.isDisjoint(with: self.chatFilters) else {
                    return nil
                }
                return ChatMessage(
                    from: payload,
                    chatRoomID: self.roomID,
                    channel: self.chatChannel.name,
                    timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                    actions: message.messageActions,
                    userID: self.userID
                )
            case .messageDeleted(let payload):
                deletedMessageIDs.insert(ChatMessageID(payload.id))
                return nil
            case .imageCreated(let payload):
                return ChatMessage(
                    from: payload,
                    chatRoomID: self.roomID,
                    channel: self.chatChannel.name,
                    timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                    actions: message.messageActions,
                    userID: self.userID
                )
            case .imageDeleted(let payload):
                deletedMessageIDs.insert(ChatMessageID(payload.id))
                return nil
            }
        }

        let messagesToBeShown = processedHistory.filter { !deletedMessageIDs.contains($0.messageID) }
        return messagesToBeShown
    }
    
    func disconnect() {
        chatChannel.disconnect()
    }

    func pause() {
        chatChannel.pause()
    }

    func resume() {
        chatChannel.resume()
    }

    func enterOpenChannel(_ channel: String) -> Promise<Void> {
        return Promise(value: ())
    }

    func enterOpenChannel(_ channel: String, sessionId: String) -> Promise<Void> {
        return self.enterOpenChannel(channel)
    }

    @discardableResult
    func exitChannel(_ channel: String) -> Promise<Void> {
        return Promise(value: ())
    }

    func exitChannel(_ channel: String, sessionId: String) {
        self.exitChannel(channel)
    }
    
    func deleteMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID> {
        return sendMessage(clientMessage, messageID: messageID, messageEvent: .messageDeleted)
    }
    
    func reportMessage(withID id: ChatMessageID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = self.messages.first(where: { $0.messageID == id}) else {
            return completion(.failure(PubSubChatRoomError.failedToFindReportedChatMessage(messageId: id.asString)))
        }
        guard let messageReporter = self.messageReporter else {
            return completion(.failure(PubSubChatRoomError.failedDueToMissingMessageReporter))
        }
        
        var messageBody = ""
        if let messageImageUrlString = message.imageURL?.absoluteString {
            messageBody = messageImageUrlString
        } else {
            messageBody = message.text ?? ""
        }
        
        let reportBody = ReportBody(
            channel: self.chatChannel.name,
            profileId: self.userID.asString,
            nickname: self.nickname.currentNickname ?? "*** ERROR: Unknown Nickname ***",
            messageId: id.asString,
            message: messageBody
        )
        messageReporter.report(reportBody: reportBody, completion: completion)
    }

    func sendMessageReaction(
        _ messageID: ChatMessageID,
        reaction: ReactionID,
        reactionsToRemove: ReactionVote.ID?
    ) -> Promise<Void> {
        return Promise { [weak self] fulfill, reject in
            guard let self = self else { return }

            guard let pubsubID = self.chatMessageIDsToPubSubIDs[messageID] else {
                return reject(PubSubChatRoomError.failedToFindPubSubID(messageID: messageID))
            }

            // If there are reactions to remove then only send new reactions after removal
            // Otherwise add new reations immediately
            if let reactionsToRemove = reactionsToRemove {
                guard let pubsubActionID = reactionsToRemove.internalID as? PubSubID else {
                    return reject(PubSubChatRoomError.reactionIdInternalNotPubSubID)
                }

                self.chatChannel.removeMessageAction(
                    messageID: pubsubID,
                    messageActionID: pubsubActionID
                ) { result in
                    switch result {
                    case .success:
                        log.dev("Successfully removed message action.")
                        // Adding reaction
                        self.chatChannel.sendMessageAction(
                            type: MessageActionType.reactionCreated.rawValue,
                            value: reaction.asString,
                            messageID: pubsubID
                        ) { result in
                            switch result {
                            case .success:
                                log.dev("Successfully send message action after removing.")
                                fulfill(())
                            case .failure(let error):
                                reject(error)
                            }
                        }
                    case .failure(let error):
                        reject(error)
                    }
                }
            } else {
                // Adding reaction
                self.chatChannel.sendMessageAction(
                    type: MessageActionType.reactionCreated.rawValue,
                    value: reaction.asString,
                    messageID: pubsubID
                ) { result in
                    switch result {
                    case .success:
                        log.dev("Successfully send message action.")
                        fulfill(())
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        }
    }

    func removeMessageReactions(
        reaction: ReactionVote.ID,
        fromMessageWithID messageID: ChatMessageID
    ) -> Promise<Void> {
        return Promise { [weak self] fulfill, reject in
            guard let self = self else { return }

            guard let pubsubID = self.chatMessageIDsToPubSubIDs[messageID] else {
                return reject(PubSubChatRoomError.failedToFindPubSubID(messageID: messageID))
            }

            guard let pubsubActionID = reaction.internalID as? PubSubID else {
                return reject(PubSubChatRoomError.reactionIdInternalNotPubSubID)
            }

            self.chatChannel.removeMessageAction(
                messageID: pubsubID,
                messageActionID: pubsubActionID
            ) { result in
                switch result {
                case .success:
                    log.dev("Successfully removed message action")
                    fulfill(())
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }

    func loadInitialHistory(completion: @escaping (Result<Void, Error>) -> Void) {
        self.chatChannel.fetchHistory(
            oldestMessageDate: nil,
            newestMessageDate: nil,
            limit: 100
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(historyResult):
                self.oldestChatMessageTimetoken = historyResult.oldestMessageTimetoken
                let messagesToBeShown = self.processMessagesFromChatHistory(historyResult: historyResult)
                self.delegates.publish{ $0.chatSession(self, didRecieveMessageHistory: messagesToBeShown) }
                messagesToBeShown.forEach { message in
                    guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.messageID] else {
                        log.error("Failed to find pubsubID for message \(message.id)")
                        return
                    }
                    self.chatMessages[pubsubID] = message
                }
                self.messages = messagesToBeShown
                completion(.success(()))
            case let .failure(error):
                if case PubNubChannelError.foundNoResultsForChannel = error {
                    self.delegates.publish { $0.chatSession(self, didRecieveMessageHistory: [])}
                    completion(.success(()))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func loadNextHistory(completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        guard !isLoadingHistory else {
            return completion(.failure(ChatSessionError.concurrentLoadHistoryCalls))
        }
        self.isLoadingHistory = true
        self.chatChannel.fetchHistory(
            oldestMessageDate: self.oldestChatMessageTimetoken,
            newestMessageDate: nil,
            limit: 100
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(historyResult):
                self.oldestChatMessageTimetoken = historyResult.oldestMessageTimetoken
                let messagesToBeShown = self.processMessagesFromChatHistory(historyResult: historyResult)
                self.delegates.publish{ $0.chatSession(self, didRecieveMessageHistory: messagesToBeShown) }
                messagesToBeShown.forEach { message in
                    guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.messageID] else {
                        log.error("Failed to find pubsubID for message \(message.id)")
                        return
                    }
                    self.chatMessages[pubsubID] = message
                }
                self.messages.insert(contentsOf: messagesToBeShown, at: 0)
                self.isLoadingHistory = false
                completion(.success(messagesToBeShown))
            case let .failure(error):
                if case PubNubChannelError.foundNoResultsForChannel = error {
                    log.info("Reached the end of the chat room history.")
                    self.delegates.publish { $0.chatSession(self, didRecieveMessageHistory: [])}
                    self.isLoadingHistory = false
                    completion(.success([]))
                } else {
                    self.isLoadingHistory = false
                    completion(.failure(error))
                }
            }
        }
    }

    func unsubscribeFromAllChannels() {
    }
    
    func updateUserChatRoomImage(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.avatarURL = url
            completion(.success(()))
        }
    }
    
    func sendMessage(_ chatMessage: NewChatMessage, completion: @escaping (Result<ChatMessageID, Error>) -> Void) {
        sendMessage(chatMessage: chatMessage, messageID: chatMessage.messageID, messageEvent: .messageCreated, completion: completion)
    }
}

// MARK: - Models

enum PubSubChatEvent: String, Codable {
    case messageCreated = "message-created"
    case messageDeleted = "message-deleted"
    case imageCreated = "image-created"
    case imageDeleted = "image-deleted"
}

/// Used to decode chat messages from a PubSubService
class PubSubChatMessageDecoder {
    enum PubSubChatEventWithPayload {
        case messageCreated(PubSubChatPayload)
        case messageDeleted(PubSubChatPayload)
        case imageCreated(PubSubImagePayload)
        case imageDeleted(PubSubImagePayload)
    }

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return decoder
    }()

    static let shared = PubSubChatMessageDecoder()

    func decode(dict: [String: Any]) throws -> PubSubChatEventWithPayload {
        guard let eventString = dict["event"] as? String else {
            throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "'event' is missing from PubSubChatEventWithPayload")
        }

        guard let event: PubSubChatEvent = PubSubChatEvent(rawValue: eventString) else {
            throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "Failed to create PubSubChatEvent")
        }

        switch event {
        case .messageCreated:
            guard let messagePayload = dict["payload"] else {
                throw PubSubChatRoomDecodeError.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubChatPayload.self,
                                                                 from: payloadData)
                return .messageCreated(chatMessagePayload)
            } catch {
                throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "\(error)")
            }
        case .messageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw PubSubChatRoomDecodeError.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubChatPayload.self,
                                                                 from: payloadData)
                return .messageDeleted(chatMessagePayload)
            } catch {
                throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "\(error)")
            }
        case .imageCreated:
            guard let messagePayload = dict["payload"] else {
                throw PubSubChatRoomDecodeError.missingPayload
            }

            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubImagePayload.self,
                                                                 from: payloadData)
                return .imageCreated(chatMessagePayload)
            } catch {
                throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "\(error)")
            }
        case .imageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw PubSubChatRoomDecodeError.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubImagePayload.self,
                                                                 from: payloadData)
                return .imageDeleted(chatMessagePayload)
            } catch {
                throw PubSubChatRoomDecodeError.failedToDecodePayload(decodingError: "\(error)")
            }
        }
    }
}

struct PubSubChatPayload: Codable {
    var id: String
    var message: String?
    var senderId: String?
    var senderNickname: String?
    var senderImageUrl: URL?
    var programDateTime: Date?
    // The message after it has been filtered
    var filteredMessage: String?
    // The reasons why a message was filtered
    var contentFilter: [ChatFilter]?
    
    var filteredSet: Set<ChatFilter> {
        return Set(contentFilter ?? [])
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case message
        case senderId
        case senderNickname
        case senderImageUrl
        case programDateTime
        case filteredMessage
        case contentFilter
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id).lowercased()
        self.message = try? container.decode(String.self, forKey: .message)
        self.senderId = try? container.decode(String.self, forKey: .senderId)
        self.senderNickname = try? container.decode(String.self, forKey: .senderNickname)
        self.senderImageUrl = try? container.decode(URL.self, forKey: .senderImageUrl)
        self.programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
        self.filteredMessage = try? container.decode(String.self, forKey: .filteredMessage)
        self.contentFilter = try? container.decode([ChatFilter].self, forKey: .contentFilter)
    }
    
    init(id: String,
         message: String?,
         senderId: String?,
         senderNickname: String?,
         senderImageUrl: URL?,
         programDateTime: Date?,
         filteredMessage: String?,
         contentFilter: [ChatFilter]?) {
        self.id = id.lowercased()
        self.message = message
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderImageUrl = senderImageUrl
        self.programDateTime = programDateTime
        self.filteredMessage = filteredMessage
        self.contentFilter = contentFilter
    }
}

struct PubSubImagePayload: Codable {
    let id: String
    let imageUrl: URL
    let imageHeight: Int
    let imageWidth: Int
    let senderId: String
    let senderNickname: String
    let senderImageUrl: URL?
    let programDateTime: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case imageUrl
        case imageHeight
        case imageWidth
        case senderId
        case senderNickname
        case senderImageUrl
        case programDateTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id).lowercased()
        self.imageUrl = try container.decode(URL.self, forKey: .imageUrl)
        self.imageHeight = try container.decode(Int.self, forKey: .imageHeight)
        self.imageWidth = try container.decode(Int.self, forKey: .imageWidth)
        self.senderId = try container.decode(String.self, forKey: .senderId)
        self.senderNickname = try container.decode(String.self, forKey: .senderNickname)
        self.senderImageUrl = try? container.decode(URL.self, forKey: .senderImageUrl)
        self.programDateTime = try? container.decode(Date.self, forKey: .programDateTime)
    }
    
    init(id: String,
         imageUrl: URL,
         imageHeight: Int,
         imageWidth: Int,
         senderId: String,
         senderNickname: String,
         senderImageUrl: URL?,
         programDateTime: Date?) {
        self.id = id.lowercased()
        self.imageUrl = imageUrl
        self.imageHeight = imageHeight
        self.imageWidth = imageWidth
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderImageUrl = senderImageUrl
        self.programDateTime = programDateTime
    }
}

struct PubSubChatMessage: Codable {
    let event: PubSubChatEvent
    let payload: PubSubChatPayload

    init(event: PubSubChatEvent, payload: PubSubChatPayload){
        self.event = event
        self.payload = payload
    }
}

struct PubSubChatImage: Codable {
    let event: PubSubChatEvent
    let payload: PubSubImagePayload
    init(event: PubSubChatEvent, payload: PubSubImagePayload) {
        self.event = event
        self.payload = payload
    }
}

enum MessageActionType: String, Decodable {
    case reactionCreated = "rc"
}
