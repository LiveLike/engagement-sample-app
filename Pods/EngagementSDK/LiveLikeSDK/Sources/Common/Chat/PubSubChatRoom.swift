//
//  PubSubChatRoom.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/19/19.
//

import UIKit

class PubSubChatRoom: NSObject, InternalChatSessionProtocol {
    
    private let messageHistoryLimit: UInt
    private var chatChannel: PubSubChannel
    private let reactionChannel: PubSubChannel?
    private var _availableReactions: [ReactionID] = []
    private let userID: ChatUser.ID
    private let nickname: UserNicknameVendor
    private let _roomID: String
    private var userChatRoomImageUrl: URL?
    private var oldestChatMessageTimetoken: TimeToken?
    // where deleted message id's are stored
    private var deletedMessageIDs: Set<ChatMessageID> = Set()
    private var imageUploader: ImageUploader
    private var chatMessages: [PubSubID: ChatMessage] = [:]

    // maps ChatMessageIDs to PubSubIDs
    private var chatMessageIDsToPubSubIDs: [ChatMessageID: PubSubID] = [:]

    private var mockedMessageIDs: Set<ChatMessageID> = Set()

    public var messages: [ChatMessage] = []

    private let messageReporter: MessageReporter?
    let blockList: BlockList
    let eventRecorder: EventRecorder
    let stickerRepository: StickerRepository
    let reactionsViewModelFactory: ReactionsViewModelFactory
    let reactionsVendor: ReactionVendor
    var isReportingEnabled: Bool {
        return messageReporter != nil
    }
    
    private var publicDelegates: Listener<ChatSessionDelegate> = Listener()
    private var delegates: Listener<InternalChatSessionDelegate> = Listener()

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
        reactionChannel: PubSubChannel?,
        userID: ChatUser.ID,
        nickname: UserNicknameVendor,
        imageUploader: ImageUploader,
        eventRecorder: EventRecorder,
        stickerRepository: StickerRepository,
        reactionsViewModelFactory: ReactionsViewModelFactory,
        reactionsVendor: ReactionVendor,
        messageHistoryLimit: UInt,
        messageReporter: MessageReporter?
    ) {
        self._roomID = roomID
        self.chatChannel = chatChannel
        self.reactionChannel = reactionChannel
        self.userID = userID
        self.nickname = nickname
        self.imageUploader = imageUploader
        self.blockList = BlockList(for: userID)
        self.eventRecorder = eventRecorder
        self.stickerRepository = stickerRepository
        self.reactionsViewModelFactory = reactionsViewModelFactory
        self.reactionsVendor = reactionsVendor
        self.messageHistoryLimit = messageHistoryLimit
        self.messageReporter = messageReporter
        super.init()

        self.chatChannel.delegate = self
    }
    
    deinit {
        log.info("Chat Session for room \(roomID) has ended.")
    }
}

// MARK: - Private methods

private extension PubSubChatRoom {
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
                    friendName: nil,
                    badgeImageURL: clientMessage.badge?.imageURL
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
                    profileImageUrl: self.userChatRoomImageUrl,
                    createdAt: TimeToken(pubnubTimetoken: 0),
                    bodyImageUrl: imageURL,
                    bodyImageSize: CGSize(width: Int(imageSize.width), height: Int(imageSize.width))
                )
                self.mockedMessageIDs.insert(mockMessage.id)
                self.messages.append(mockMessage)
                self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage )}
                self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: mockMessage) }

                // Send real message

                Cache.shared.get(
                    key: imageURL.absoluteString
                ) { [weak self] (imageData: Data?) in
                    guard let self = self else {
                        return reject(PubSubChatRoomError.promiseRejectedDueToNilSelf)
                    }
                    guard let imageData = imageData else {
                        return reject(PubSubChatRoomError.failedToSendImageDueToMissingData)
                    }
                    // upload image
                    self.imageUploader.upload(imageData) { [weak self] result in
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
                                senderImageUrl: self.userChatRoomImageUrl,
                                badgeImageUrl: clientMessage.badge?.imageURL,
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
                                    mockMessage.id = ChatMessageID(pubsubID)
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
                }
            }
        } else if let message = clientMessage.message {
            let payload = PubSubChatPayload(
                id: messageID,
                message: message,
                senderId: userID.asString,
                senderNickname: nickname,
                senderImageUrl: userChatRoomImageUrl,
                badgeImageUrl: clientMessage.badge?.imageURL,
                programDateTime: pdt
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
                    let chatMessageType = ChatMessage(
                        from: payload,
                        channel: self.chatChannel.name,
                        timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                        actions: message.messageActions,
                        userID: self.userID
                    )
                    self.chatMessageIDsToPubSubIDs[chatMessageType.id] = message.pubsubID
                    return chatMessageType
                case .messageDeleted(let payload):
                    let id = ChatMessageID(payload.id)
                    deletedMessageIDs.insert(id)
                    return nil
                case .imageCreated(let payload):
                    let chatMessageType = ChatMessage(
                        from: payload,
                        channel: self.chatChannel.name,
                        timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                        actions: message.messageActions,
                        userID: self.userID
                    )

                    self.chatMessageIDsToPubSubIDs[chatMessageType.id] = message.pubsubID
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

        let messagesToBeShown = unfilteredMessages.filter { !deletedMessageIDs.contains($0.id) }
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
                channel: roomID,
                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                actions: message.messageActions,
                userID: userID
            )
            self.messages.append(chatMessage)
            self.publicDelegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
            self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: chatMessage)}
            chatMessages[message.pubsubID] = chatMessage
            self.chatMessageIDsToPubSubIDs[chatMessage.id] = message.pubsubID
        case .messageDeleted(let payload):
            let chatMessageID = ChatMessageID(payload.id)
            self.delegates.publish { $0.chatSession(self, didRecieveMessageDeleted: chatMessageID)}
            deletedMessageIDs.insert(chatMessageID)
            chatMessages.removeValue(forKey: message.pubsubID)
        case .imageCreated(let payload):
            let chatMessage = ChatMessage(
                from: payload,
                channel: roomID,
                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                actions: message.messageActions,
                userID: userID
            )

            if self.chatMessageIDsToPubSubIDs[chatMessage.id] == nil {
                // only publish downstream here if pubsub id doesn't exist yet
                // if pubsub id already exists then this message was mocked and published earlier
                self.chatMessageIDsToPubSubIDs[chatMessage.id] = message.pubsubID
                chatMessages[message.pubsubID] = chatMessage
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

    var availableReactions: [ReactionID] {
        get {
            return _availableReactions
        }
        set {
            _availableReactions = newValue
        }
    }
    
    func getMessages(since timestamp: TimeToken, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        self.chatChannel.fetchHistory(
            oldestMessageDate: timestamp,
            newestMessageDate: nil,
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
                        return ChatMessage(
                            from: payload,
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

                let messagesToBeShown = processedHistory.filter { !deletedMessageIDs.contains($0.id) }
                completion(.success(messagesToBeShown))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func getMessageCount(since timestamp: TimeToken, completion: @escaping (Result<Int, Error>) -> Void) {
        self.chatChannel.messageCount(
            since: timestamp,
            completion: completion
        )
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

    func sendMessage(_ clientMessage: ClientMessage) -> Promise<ChatMessageID> {
        return sendMessage(clientMessage, messageID: UUID().uuidString, messageEvent: .messageCreated)
    }
    
    func updateMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID> {
        return sendMessage(clientMessage, messageID: messageID, messageEvent: .messageUpdated)
    }
    
    func deleteMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID> {
        return sendMessage(clientMessage, messageID: messageID, messageEvent: .messageDeleted)
    }
    
    func reportMessage(withID id: ChatMessageID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = self.messages.first(where: { $0.id == id}) else {
            return completion(.failure(PubSubChatRoomError.failedToFindReportedChatMessage(messageId: id.asString)))
        }
        guard let messageReporter = self.messageReporter else {
            return completion(.failure(PubSubChatRoomError.failedDueToMissingMessageReporter))
        }
        let reportBody = ReportBody(
            channel: self.chatChannel.name,
            userId: self.userID.asString,
            nickname: self.nickname.currentNickname ?? "*** ERROR: Unknown Nickname ***",
            messageId: id.asString,
            message: message.message
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
                    guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.id] else {
                        log.error("Failed to find pubsubID for message \(message.id)")
                        return
                    }
                    self.chatMessages[pubsubID] = message
                }
                self.messages = messagesToBeShown
                completion(.success(()))
            case let .failure(error):
                if case PubNubChannel.Errors.foundNoResultsForChannel = error {
                    self.delegates.publish { $0.chatSession(self, didRecieveMessageHistory: [])}
                    completion(.success(()))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func loadPreviousMessagesFromHistory() -> Promise<Void> {
        return Promise(work: { fulfill, reject in
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
                        guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.id] else {
                            log.error("Failed to find pubsubID for message \(message.id)")
                            return
                        }
                        self.chatMessages[pubsubID] = message
                    }
                    self.messages.insert(contentsOf: messagesToBeShown, at: 0)
                    fulfill(())
                case let .failure(error):
                    if case PubNubChannel.Errors.foundNoResultsForChannel = error {
                        log.info("Reached the end of the chat room history.")
                        self.delegates.publish { $0.chatSession(self, didRecieveMessageHistory: [])}
                        fulfill(())
                    } else {
                        reject(error)
                    }
                }
            }
        })
    }

    func unsubscribeFromAllChannels() {
    }

    func updateUserChatImage(url: URL) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
             DispatchQueue.main.async {
                 if UIApplication.shared.canOpenURL(url) {
                     self.userChatRoomImageUrl = url
                     fulfill(())
                 } else {
                    log.error("Unable to set user chat image url for url: \(url.absoluteString)")
                    reject(PubSubChatRoomError.invalidUserChatRoomImageUrl)
                 }
             }
        }
    }
}

// MARK: - Models

enum PubSubChatEvent: String, Codable {
    case messageCreated = "message-created"
    case messageUpdated = "message-updated"
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
            throw Errors.failedToDecodePayload(decodingError: "'event' is missing from PubSubChatEventWithPayload")
        }

        guard let event: PubSubChatEvent = PubSubChatEvent(rawValue: eventString) else {
            throw Errors.failedToDecodePayload(decodingError: "Failed to create PubSubChatEvent")
        }

        switch event {
        case .messageCreated:
            guard let messagePayload = dict["payload"] else {
                throw Errors.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubChatPayload.self,
                                                                 from: payloadData)
                return .messageCreated(chatMessagePayload)
            } catch {
                throw Errors.failedToDecodePayload(decodingError: "\(error)")
            }
        case .messageUpdated:
            throw NilError()
        case .messageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw Errors.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubChatPayload.self,
                                                                 from: payloadData)
                return .messageDeleted(chatMessagePayload)
            } catch {
                throw Errors.failedToDecodePayload(decodingError: "\(error)")
            }
        case .imageCreated:
            guard let messagePayload = dict["payload"] else {
                throw Errors.missingPayload
            }

            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubImagePayload.self,
                                                                 from: payloadData)
                return .imageCreated(chatMessagePayload)
            } catch {
                throw Errors.failedToDecodePayload(decodingError: "\(error)")
            }
        case .imageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw Errors.missingPayload
            }
            
            do {
                let payloadData = try JSONSerialization.data(withJSONObject: messagePayload,
                                                             options: .prettyPrinted)
                let chatMessagePayload = try self.decoder.decode(PubSubImagePayload.self,
                                                                 from: payloadData)
                return .imageDeleted(chatMessagePayload)
            } catch {
                throw Errors.failedToDecodePayload(decodingError: "\(error)")
            }
        }
    }

    enum Errors: LocalizedError {
        case failedToDecodePayload(decodingError: String)
        case missingPayload
        
        var errorDescription: String? {
            switch self {
            case .failedToDecodePayload(let decodingError):
                return "\(decodingError)"
            case .missingPayload:
                return "'payload' is missing from PubSubChatEventWithPayload"
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
    var badgeImageUrl: URL?
    var programDateTime: Date?
}

struct PubSubImagePayload: Codable {
    let id: String
    let imageUrl: URL
    let imageHeight: Int
    let imageWidth: Int
    let senderId: String
    let senderNickname: String
    let senderImageUrl: URL?
    let badgeImageUrl: URL?
    let programDateTime: Date?
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

private enum PubSubChatRoomError: LocalizedError {
    case invalidUserChatRoomImageUrl
    case failedToEncodeChatMessage
    case sendMessageFailedNoNickname
    case failedToFindPubSubID(messageID: ChatMessageID)
    case reactionIdInternalNotPubSubID
    case failedToFindChatMessageForPubSubID(pubsubID: PubSubID)
    case failedToFindReportedChatMessage(messageId: String)
    case promiseRejectedDueToNilSelf
    case failedToSendImageDueToMissingData
    case failedDueToMissingMessageReporter

    var errorDescription: String? {
        switch self {
        case .invalidUserChatRoomImageUrl:
            return "The user chat image url provided is not valid"
        case .failedToEncodeChatMessage:
            return "The SDK failed to decode the chat message to json."
        case .sendMessageFailedNoNickname:
            return "The SDK failed to send the message because there is no user nickname set."
        case .failedToFindPubSubID(let messageID):
            return "Failed to find PubSubID for message with id: \(messageID)"
        case .reactionIdInternalNotPubSubID:
            return "Failed because internal id of reaction is not of type PubSubID"
        case .failedToFindChatMessageForPubSubID(let pubsubID):
            return "Failed to find the ChatMessageType for pubsub message with id: \(pubsubID)"
        case .failedToFindReportedChatMessage(let messageId):
        return "Failed to find message that is being reported with id: \(messageId)"
        case .promiseRejectedDueToNilSelf:
            return "Promise rejected due to self being nil"
        case .failedToSendImageDueToMissingData:
            return "Failed to send image message because expected imageData cannot be retrieved from cache."
        case .failedDueToMissingMessageReporter:
        return "Failed to report a message because the message reporter has not been found"
        }
    }
}
