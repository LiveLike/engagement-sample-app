//
//  PubSubChatRoom.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/19/19.
//

import UIKit

class PubSubChatRoom: NSObject {
    private var chatChannel: PubSubChannel
    private let reactionChannel: PubSubChannel?
    private var _availableReactions: [ReactionID] = []
    private var _downStreamProxyInput: ChatProxyInput?
    private let userID: ChatUser.ID
    private let nickname: UserNicknameVendor
    private let _roomID: String
    private var userChatRoomImageUrl: URL?
    private var oldestChatMessageTimetoken: Date?
    // where deleted message id's are stored
    private var deletedMessageIDs: Set<ChatMessageID> = Set()
    private var imageUploader: ImageUploader
    private var chatMessages: [PubSubID: ChatMessageType] = [:]

    // maps ChatMessageIDs to PubSubIDs
    private var chatMessageIDsToPubSubIDs: [ChatMessageID: PubSubID] = [:]

    private var mockedMessageIDs: Set<ChatMessageID> = Set()

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
        imageUploader: ImageUploader
    ) {
        self._roomID = roomID
        self.chatChannel = chatChannel
        self.reactionChannel = reactionChannel
        self.userID = userID
        self.nickname = nickname
        self.imageUploader = imageUploader
        super.init()

        self.chatChannel.delegate = self
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
                var mockMessage = ChatMessageType(
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
                self.downStreamProxyInput?.publish(newMessage: mockMessage)

                // Send real message

                Cache.shared.get(
                    key: imageURL.absoluteString
                ) { [weak self] (imageData: Data?) in
                    guard let self = self else {
                        return reject(NilError())
                    }
                    guard let imageData = imageData else {
                        log.error("Failed to send image message because expected imageData to be in cache.")
                        return reject(NilError())
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
    private func processMessagesFromChatHistory(historyResult: PubSubHistoryResult) -> [ChatMessageType] {
        let unfilteredMessages: [ChatMessageType] = historyResult.messages.compactMap { message in
            guard let payload = try? PubSubChatMessageDecoder.shared.decode(dict: message.message) else {
                log.error("Failed to decode a pub sub chat message")
                return nil
            }

            switch payload {
            case .messageCreated(let payload):
                let chatMessageType = ChatMessageType(
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
            case .messageUpdated(_):
                return nil
            case .imageCreated(let payload):
                let chatMessageType = ChatMessageType(
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
            let chatMessage = ChatMessageType(
                from: payload,
                channel: roomID,
                timetoken: TimeToken(pubnubTimetoken: message.createdAt),
                actions: message.messageActions,
                userID: userID
            )
            downStreamProxyInput?.publish(newMessage: chatMessage)
            chatMessages[message.pubsubID] = chatMessage
            self.chatMessageIDsToPubSubIDs[chatMessage.id] = message.pubsubID
        case .messageDeleted(let payload):
            let chatMessageID = ChatMessageID(payload.id)
            downStreamProxyInput?.deleteMessage(
                channel: channel.name,
                messageId: chatMessageID
            )
            deletedMessageIDs.insert(chatMessageID)
            chatMessages.removeValue(forKey: message.pubsubID)
        case .messageUpdated(let payload):
            return
        case .imageCreated(let payload):
            let chatMessage = ChatMessageType(
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
                downStreamProxyInput?.publish(newMessage: chatMessage)
            }
        case .imageDeleted(let payload):
            let chatMessageID = ChatMessageID(payload.id)
            downStreamProxyInput?.deleteMessage(
                channel: channel.name,
                messageId: chatMessageID
            )
            deletedMessageIDs.insert(chatMessageID)
            chatMessages.removeValue(forKey: message.pubsubID)
        }
    }

    func channel(_ channel: PubSubChannel, messageActionCreated messageAction: PubSubMessageAction) {
        guard var chatMessageType = self.chatMessages[messageAction.messageID] else {
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
        self.downStreamProxyInput?.publish(messageUpdated: chatMessageType)
    }

    func channel(_ channel: PubSubChannel, messageActionDeleted messageActionID: PubSubID, messageID: PubSubID) {
        guard var chatMessageType = self.chatMessages[messageID] else {
            log.error(PubSubChatRoomError.failedToFindChatMessageForPubSubID(pubsubID: messageID))
            return
        }
        let voteID = ReactionVote.ID(messageActionID)
        chatMessageType.reactions.allVotes.removeAll(where: { $0.voteID == voteID })
        self.chatMessages[messageID] = chatMessageType
        self.downStreamProxyInput?.publish(messageUpdated: chatMessageType)
    }
}

// MARK: - ChatMessagingOutput

extension PubSubChatRoom: ChatMessagingOutput {

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

    var downStreamProxyInput: ChatProxyInput? {
        get {
            return _downStreamProxyInput
        }
        set {
            _downStreamProxyInput = newValue
        }
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

    func loadNewestMessagesFromHistory(limit: Int) -> Promise<Void> {
        return Promise(work: { fulfill, reject in
            self.chatChannel.fetchHistory(
                oldestMessageDate: nil,
                newestMessageDate: nil,
                limit: UInt(limit)
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(historyResult):
                    self.oldestChatMessageTimetoken = historyResult.oldestMessageTimetoken
                    let messagesToBeShown = self.processMessagesFromChatHistory(historyResult: historyResult)
                    messagesToBeShown.filter { self.mockedMessageIDs.contains($0.id) }.forEach { mockedMessage in
                        guard let pubsubID = self.chatMessageIDsToPubSubIDs[mockedMessage.id] else { return }
                        self.chatMessages[pubsubID] = mockedMessage
                        self.downStreamProxyInput?.publish(messageUpdated: mockedMessage)
                    }
                    self.downStreamProxyInput?.publish(
                        channel: self.chatChannel.name,
                        newestMessages: messagesToBeShown.filter { !self.mockedMessageIDs.contains($0.id) }
                    )
                    messagesToBeShown.forEach { message in
                        guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.id] else {
                            log.error("Failed to find pubsubID for message \(message.id)")
                            return
                        }
                        self.chatMessages[pubsubID] = message
                    }
                    fulfill(())
                case let .failure(error):
                    reject(error)
                }
            }
        })
    }

    func loadInitialHistory(limit: Int) -> Promise<Void> {
        return Promise(work: { fulfill, reject in
            self.chatChannel.fetchHistory(
                oldestMessageDate: nil,
                newestMessageDate: nil,
                limit: UInt(limit)
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(historyResult):
                    self.oldestChatMessageTimetoken = historyResult.oldestMessageTimetoken
                    let messagesToBeShown = self.processMessagesFromChatHistory(historyResult: historyResult)
                    self.downStreamProxyInput?.publish(channel: self.chatChannel.name, messagesFromHistory: messagesToBeShown)
                    messagesToBeShown.forEach { message in
                        guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.id] else {
                            log.error("Failed to find pubsubID for message \(message.id)")
                            return
                        }
                        self.chatMessages[pubsubID] = message
                    }
                    fulfill(())
                case let .failure(error):
                    if case PubNubChannel.Errors.foundNoResultsForChannel = error {
                        self.downStreamProxyInput?.publish(
                            channel: self.chatChannel.name,
                            messagesFromHistory: []
                        )
                        fulfill(())
                    } else {
                        reject(error)
                    }
                }
            }
        })
    }

    func loadPreviousMessagesFromHistory(limit: Int) -> Promise<Void> {
        return Promise(work: { fulfill, reject in
            self.chatChannel.fetchHistory(
                oldestMessageDate: self.oldestChatMessageTimetoken,
                newestMessageDate: nil,
                limit: UInt(limit)
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(historyResult):
                    self.oldestChatMessageTimetoken = historyResult.oldestMessageTimetoken
                    let messagesToBeShown = self.processMessagesFromChatHistory(historyResult: historyResult)
                    self.downStreamProxyInput?.publish(channel: self.chatChannel.name, messagesFromHistory: messagesToBeShown)
                    messagesToBeShown.forEach { message in
                        guard let pubsubID = self.chatMessageIDsToPubSubIDs[message.id] else {
                            log.error("Failed to find pubsubID for message \(message.id)")
                            return
                        }
                        self.chatMessages[pubsubID] = message
                    }
                    fulfill(())
                case let .failure(error):
                    reject(error)
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
        case messageUpdated(PubSubChatPayload)
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
            throw Errors.failedToDecodePayload
        }

        guard let event: PubSubChatEvent = PubSubChatEvent(rawValue: eventString) else {
            throw Errors.failedToDecodePayload
        }

        switch event {
        case .messageCreated:
            guard let messagePayload = dict["payload"] else {
                throw Errors.failedToDecodePayload
            }

            guard let payloadData = try? JSONSerialization.data(
                withJSONObject: messagePayload,
                options: .prettyPrinted
            ) else {
                throw Errors.failedToDecodePayload
            }

            guard let chatMessagePayload = try? self.decoder.decode(
                PubSubChatPayload.self,
                from: payloadData
            ) else {
                let messageAsString: String = String(data: payloadData, encoding: .utf8) ?? ""
                log.dev("Failed to decode new message as \(PubSubChatPayload.self) '\(messageAsString)'")
                throw Errors.failedToDecodePayload
            }

            return .messageCreated(chatMessagePayload)
        case .messageUpdated:
            throw NilError()
        case .messageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw Errors.failedToDecodePayload
            }

            guard let payloadData = try? JSONSerialization.data(
                withJSONObject: messagePayload,
                options: .prettyPrinted
            ) else {
                throw Errors.failedToDecodePayload
            }

            guard let chatMessagePayload = try? self.decoder.decode(
                PubSubChatPayload.self,
                from: payloadData
            ) else {
                let messageAsString: String = String(data: payloadData, encoding: .utf8) ?? ""
                log.dev("Failed to decode new message as \(PubSubChatPayload.self) '\(messageAsString)'")
                throw Errors.failedToDecodePayload
            }

            return .messageDeleted(chatMessagePayload)
        case .imageCreated:
            guard let messagePayload = dict["payload"] else {
                throw Errors.failedToDecodePayload
            }

            guard let payloadData = try? JSONSerialization.data(
                withJSONObject: messagePayload,
                options: .prettyPrinted
            ) else {
                throw Errors.failedToDecodePayload
            }

            guard let chatMessagePayload = try? self.decoder.decode(
                PubSubImagePayload.self,
                from: payloadData
            ) else {
                let messageAsString: String = String(data: payloadData, encoding: .utf8) ?? ""
                log.dev("Failed to decode new message as \(PubSubImagePayload.self) '\(messageAsString)'")
                throw Errors.failedToDecodePayload
            }

            return .imageCreated(chatMessagePayload)
        case .imageDeleted:
            guard let messagePayload = dict["payload"] else {
                throw Errors.failedToDecodePayload
            }

            guard let payloadData = try? JSONSerialization.data(
                withJSONObject: messagePayload,
                options: .prettyPrinted
            ) else {
                throw Errors.failedToDecodePayload
            }

            guard let chatMessagePayload = try? self.decoder.decode(
                PubSubImagePayload.self,
                from: payloadData
            ) else {
                let messageAsString: String = String(data: payloadData, encoding: .utf8) ?? ""
                log.dev("Failed to decode new message as \(PubSubImagePayload.self) '\(messageAsString)'")
                throw Errors.failedToDecodePayload
            }

            return .imageDeleted(chatMessagePayload)
        }
    }

    enum Errors: LocalizedError {
        case failedToDecodePayload
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
        }
    }
}
