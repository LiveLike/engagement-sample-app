//
//  SpoilerFreeChatSession.swift
//  LiveLikeSDK
//
//  Created by Jelzon Monzon on 2020-03-14.
//

import Foundation

class SpoilerFreeChatSession: InternalChatSessionProtocol {
    private var realChatRoom: InternalChatSessionProtocol
    private let queue = Queue<ChatMessage>()
    private var playerTimeSource: PlayerTimeSource?
    private var timer: DispatchSourceTimer?
    var userChatRoomImageUrl: URL?
    private let publicDelegates: Listener<ChatSessionDelegate> = Listener()
    private let delegates: Listener<InternalChatSessionDelegate> = Listener()
    
    var roomID: String {
        return realChatRoom.roomID
    }
    
    var title: String?
    
    /// The array of messages that have been synced
    var messages: [ChatMessage] = []
    
    var isReportingEnabled: Bool {
        return realChatRoom.isReportingEnabled
    }
    
    var reactionsVendor: ReactionVendor {
        return realChatRoom.reactionsVendor
    }
    
    var stickerRepository: StickerRepository {
        return realChatRoom.stickerRepository
    }
    
    var recentlyUsedStickers: LimitedArray<Sticker> = LimitedArray<Sticker>(maxSize: 30)

    var blockList: BlockList {
        return realChatRoom.blockList
    }

    var eventRecorder: EventRecorder {
        return realChatRoom.eventRecorder
    }

    var superPropertyRecorder: SuperPropertyRecorder {
        return realChatRoom.superPropertyRecorder
    }

    var peoplePropertyRecorder: PeoplePropertyRecorder {
        return realChatRoom.peoplePropertyRecorder
    }
    
    var isAvatarDisplayed: Bool {
        return realChatRoom.isAvatarDisplayed
    }
    
    var avatarURL: URL? {
        get {
            return realChatRoom.avatarURL
        }
        set {
            realChatRoom.avatarURL = newValue
        }
    }

    init(realChatRoom: InternalChatSessionProtocol, playerTimeSource: PlayerTimeSource?) {
        self.realChatRoom = realChatRoom
        self.playerTimeSource = playerTimeSource
        self.title = realChatRoom.title
        
        self.realChatRoom.addDelegate(self)
        self.realChatRoom.addInternalDelegate(self)
        timer = processQueueForEligibleScheduledEvent()
    }

    deinit {
        self.timer?.cancel()
    }

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
    
    func disconnect() {
        realChatRoom.disconnect()
    }

    func deleteMessage(_ clientMessage: ClientMessage, messageID: String) -> Promise<ChatMessageID> {
        var clientMessage = clientMessage
        clientMessage.timeStamp = self.playerTimeSource?()
        return realChatRoom.deleteMessage(clientMessage, messageID: messageID)
    }

    func reportMessage(withID id: ChatMessageID, completion: @escaping (Result<Void, Error>) -> Void) {
        realChatRoom.reportMessage(withID: id, completion: completion)
    }
    
    func sendMessageReaction(_ messageID: ChatMessageID, reaction: ReactionID, reactionsToRemove: ReactionVote.ID?) -> Promise<Void> {
        return realChatRoom.sendMessageReaction(messageID, reaction: reaction, reactionsToRemove: reactionsToRemove)
    }

    func removeMessageReactions(reaction: ReactionVote.ID, fromMessageWithID messageID: ChatMessageID) -> Promise<Void> {
        return realChatRoom.removeMessageReactions(reaction: reaction, fromMessageWithID: messageID)
    }
    
    func loadNextHistory(completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        realChatRoom.loadNextHistory(completion: completion)
    }

    func loadInitialHistory(completion: @escaping (Result<Void, Error>) -> Void) {
        return realChatRoom.loadInitialHistory(completion: completion)
    }

    func unsubscribeFromAllChannels() {
        realChatRoom.unsubscribeFromAllChannels()
    }

    func pause() {}

    func resume() {}
    
    func getMessageCount(since timestamp: TimeToken, completion: @escaping (Result<Int, Error>) -> Void) {
        realChatRoom.getMessageCount(since: timestamp, completion: completion)
    }
    
    func getMessages(since timestamp: TimeToken, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        realChatRoom.getMessages(since: timestamp, completion: completion)
    }
    
    func updateUserChatRoomImage(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        realChatRoom.avatarURL = url
        completion(.success(()))
    }

    func sendMessage(_ chatMessage: NewChatMessage, completion: @escaping (Result<ChatMessageID, Error>) -> Void) {
        realChatRoom.sendMessage(chatMessage, completion: completion)
    }
}

extension SpoilerFreeChatSession: InternalChatSessionDelegate {
    
    func chatSession(_ chatSession: ChatSession, didRecieveError error: Error) {
        delegates.publish{ $0.chatSession(self, didRecieveError: error) }
    }
    
    func chatSession(_ chatSession: ChatSession, didRecieveNewMessage newMessage: ChatMessage) {
        // check if message is currently in queue
        if self.queue.contains(where: { $0 == newMessage }) {
            return
        }

        // if message is mine then publish immediately
        if newMessage.sender.isLocalUser {
            self.messages.append(newMessage)
            self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: newMessage) }
            return
        }

        // Send message immediately if message is unscheduled or no timesource.
        if newMessage.videoTimestamp == nil || playerTimeSource?() == nil {
            self.messages.append(newMessage)
            self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: newMessage) }
            return
        }

        // Send message when timeSource has passed timeStamp
        if let timeStamp = newMessage.videoTimestamp, let timeSource = self.playerTimeSource?(), timeStamp <= timeSource {
            self.messages.append(newMessage)
            self.delegates.publish { $0.chatSession(self, didRecieveNewMessage: newMessage) }
            return
        }
        self.queue.enqueue(element: newMessage)
    }
    
    func chatSession(_ chatSession: ChatSession, didRecieveMessageHistory messages: [ChatMessage]) {
        // If there is no sync time source then publish immediately
        guard let playerTimeSourceNow = self.playerTimeSource?() else {
            self.messages.insert(contentsOf: messages, at: 0)
            delegates.publish { $0.chatSession(self, didRecieveMessageHistory: messages) }
            return
        }

        let splitMessages = self.split(messages: messages, byTimestamp: playerTimeSourceNow)
        self.messages.insert(contentsOf: splitMessages.messagesBeforeTimestamp, at: 0)

        // Publish messages that were earlier than sync timestamp
        // If there are none then go to the cache
        if splitMessages.messagesBeforeTimestamp.count > 0 {
            delegates.publish {
                $0.chatSession(self, didRecieveMessageHistory: splitMessages.messagesBeforeTimestamp)
            }
        } else {
            delegates.publish {
                $0.chatSession(self, didRecieveMessageHistory: messages)
            }
        }

        // Queue messages that are later than sync timestamp
        splitMessages.messagesAfterTimestamp.forEach { m in
            self.queue.enqueue(element: m)
        }
    }
    
    func chatSession(_ chatSession: ChatSession, didRecieveMessageUpdate message: ChatMessage) {
        delegates.publish {
            $0.chatSession(self, didRecieveMessageUpdate: message)
        }
    }
    
    func chatSession(_ chatSession: ChatSession, didRecieveMessageDeleted messageID: ChatMessageID) {
        delegates.publish {
            $0.chatSession(self, didRecieveMessageDeleted: messageID)
        }
    }
}

private extension SpoilerFreeChatSession {
    // Helper method to split an array of messages into two arrays by timestamp
    // messageBeforeTimestamp are the messages with timestamps before the given timestamp
    // messagesAfterTimestamp are the messages with timestamps after the given timestamp
    func split(
        messages: [ChatMessage],
        byTimestamp timestamp: TimeInterval
    ) -> (messagesBeforeTimestamp: [ChatMessage], messagesAfterTimestamp: [ChatMessage]) {
        // The messages that are earlier than the sync timestamp. These will be shown immediately.
        var beforeTimestamp = [ChatMessage]()

        // The messages that are later than the sync timestamp. These will be queued for sync.
        var afterTimestamp = [ChatMessage]()

        messages.forEach { message in
            // If the message doesn't have a timestamp then consider it earlier than sync timestamp
            guard let messageTimestamp = message.videoTimestamp else {
                beforeTimestamp.append(message)
                return
            }

            if messageTimestamp >= timestamp {
                afterTimestamp.append(message)
            } else {
                beforeTimestamp.append(message)
            }
        }

        return (beforeTimestamp, afterTimestamp)
    }

    func processQueueForEligibleScheduledEvent() -> DispatchSourceTimer {
        self.timer?.cancel()
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let nextMessage = self.queue.peek() else { return }

            // If we lose timesource then publish immediately
            if self.playerTimeSource == nil {
                self.messages.append(nextMessage)
                self.delegates.publish {
                    $0.chatSession(self, didRecieveNewMessage: nextMessage)
                }
                self.queue.removeNext()
                return
            }

            // Send message when timeSource has passed timeStamp
            if let timeStamp = nextMessage.videoTimestamp, let timeSource = self.playerTimeSource?(), timeStamp <= timeSource {
                self.messages.append(nextMessage)
                self.delegates.publish {
                    $0.chatSession(self, didRecieveNewMessage: nextMessage)
                }
                self.queue.removeNext()
                return
            }
        }
        timer.resume()
        return timer
    }
}
