//
//  PubNubChannel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/27/19.
//

import PubNub
import Foundation

class PubNubChannel: NSObject, PubSubChannel, PNObjectEventListener {
    weak var delegate: PubSubChannelDelegate?

    private let pubnub: PubNub
    private let _channel: String
    private let includeTimeToken: Bool
    private let includeMessageActions: Bool

    private var messageCache: [PubSubID: PubSubChannelMessage] = [:]

    var name: String {
        return _channel
    }

    var pauseStatus: PauseStatus = .unpaused

    init(
        pubnub: PubNub,
        channel: String,
        includeTimeToken: Bool,
        includeMessageActions: Bool
    ) {
        self.pubnub = pubnub
        self._channel = channel
        self.includeTimeToken = includeTimeToken
        self.includeMessageActions = includeMessageActions
        super.init()
        pubnub.addListener(self)
        pubnub.subscribeToChannels([channel], withPresence: false)
    }

    deinit {
        disconnect()
    }

    func send(
        _ message: String,
        completion: @escaping (Result<PubSubID, Error>) -> Void
    ) {
        pubnub.publish()
            .channel(self._channel)
            .message(message)
            .performWithCompletion { status in
                guard !status.isError else {
                    return completion(.failure(Errors.pubnubStatusError(errorStatus: status)))
                }

                let id = PubSubID(status.data.timetoken)
                completion(.success(id))
            }
    }

    func messageCount(
        since timestamp: TimeToken,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        self.pubnub.messageCounts()
            .channels([_channel])
            .timetokens([timestamp.pubnubTimetoken])
            .performWithCompletion { [weak self] result, status in
                guard let self = self else { return }
                if let status = status {
                    if status.isError{
                        return completion(.failure(Errors.pubnubStatusError(errorStatus: status)))
                    }
                }

                guard let result = result else {
                    return completion(.failure(Errors.noMessageCountResult))
                }

                guard let count = result.data.channels[self._channel] else {
                    return completion(.failure(Errors.noMessageCountForChannel(channel: self._channel)))
                }

                completion(.success(Int(truncating: count)))
        }
    }

    func fetchHistory(
        oldestMessageDate: TimeToken?,
        newestMessageDate: TimeToken?,
        limit: UInt,
        completion: @escaping (Result<PubSubHistoryResult, Error>) -> Void
    ) {
        self.pubnub.history()
            .channel(_channel)
            .start(optional: oldestMessageDate?.pubnubTimetoken)
            .end(optional: newestMessageDate?.pubnubTimetoken)
            .limit(limit)
            .reverse(false)
            .includeTimeToken(self.includeTimeToken)
            .includeMessageActions(self.includeMessageActions)
            .performWithCompletion { (result, status) in
                if let status = status {
                    if status.isError {
                        completion(.failure(Errors.pubnubStatusError(errorStatus: status)))
                        return
                    }
                }
                guard let result = result else {
                    completion(.failure(Errors.foundNoResultsFromHistoryRequest))
                    return
                }

                let decoder: JSONDecoder = {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
                    return decoder
                }()

                guard let channelResults = result.data.channels[self._channel] else {
                    return completion(.failure(Errors.foundNoResultsForChannel(channel: self._channel)))
                }

                let chatMessages: [PubSubChannelMessage] = channelResults.compactMap { historyMessage in
                    guard let historyMessageDict = historyMessage as? [String: Any] else {
                        log.error("Failed to case historyMessage as [String: Any]")
                        return nil
                    }

                    guard let historyData = try? JSONSerialization.data(withJSONObject: historyMessageDict, options: .prettyPrinted) else {
                        log.error("Failed to serialize historyMessageDict to json.")
                        return nil
                    }

                    guard let messageDict = historyMessageDict["message"] as? [String: Any] else {
                        log.error("Failed to find 'message' value from historyMessageDict.")
                        return nil
                    }

                    do {
                        let history = try decoder.decode(PubNubHistoryMessage.self, from: historyData)
                        var messageActions: [PubSubMessageAction] = []
                        history.actions?.forEach { typeKVP in
                            let type = typeKVP.key
                            typeKVP.value.forEach { preValueKVP in
                                let value = preValueKVP.key
                                preValueKVP.value.forEach { valueKVP in
                                    let actionTimetoken = valueKVP.actionTimetoken
                                    let uuid = valueKVP.uuid
                                    messageActions.append(
                                        PubSubMessageAction(
                                            messageID: PubSubID(history.timetoken),
                                            id: PubSubID(actionTimetoken),
                                            sender: uuid,
                                            type: type,
                                            value: value,
                                            timetoken: NSNumber(value: actionTimetoken),
                                            messageTimetoken: NSNumber(value: history.timetoken)
                                        )
                                    )
                                }
                            }
                        }
                        
                        return PubSubChannelMessage(
                            pubsubID: PubSubID(history.timetoken),
                            message: messageDict,
                            createdAt: NSNumber(value: history.timetoken),
                            messageActions: messageActions
                        )
                    } catch {
                        log.error("Failed to decode historyData as PubNubHistoryMessage.\n \(error)")
                        return nil
                    }
                }

                completion(
                    .success(
                        PubSubHistoryResult(
                            newestMessageTimetoken: TimeToken(pubnubTimetoken: chatMessages.last!.createdAt),
                            oldestMessageTimetoken: TimeToken(pubnubTimetoken: chatMessages.first!.createdAt),
                            messages: chatMessages
                        )
                    )
                )
        }
    }

    func sendMessageAction(
        type: String,
        value: String,
        messageID: PubSubID,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let messageTimetoken = messageID.internalID as? NSNumber else {
            return completion(.failure(Errors.expectedPubSubIDInternalToBeNSNumber))
        }

        pubnub.addMessageAction()
            .type(type)
            .value(value)
            .channel(_channel)
            .messageTimetoken(messageTimetoken)
            .performWithCompletion { [weak self] status in
                guard let self = self else { return }
                guard !status.isError else {
                    log.error(status.errorData.information)
                    if status.statusCode == 409 {
                        completion(.failure(Errors.messageActionAlreadyAdded))
                    } else {
                        completion(.failure(Errors.failedToSendMessageAction))
                    }
                    return
                }

                guard let action = status.data.action else {
                    completion(.failure(Errors.foundNoAction))
                    return
                }

                let messageID = PubSubID(action.messageTimetoken)
                let actionID = PubSubID(action.actionTimetoken)
                let pnMessageAction = PubSubMessageAction(
                    messageID: messageID,
                    id: actionID,
                    sender: action.uuid,
                    type: type,
                    value: value,
                    timetoken: action.actionTimetoken,
                    messageTimetoken: action.messageTimetoken
                )
                self.messageCache[actionID]?.messageActions.append(pnMessageAction)
                self.delegate?.channel(
                    self,
                    messageActionCreated: pnMessageAction
                )
                completion(.success(true))
            }
    }

    func removeMessageAction(
        messageID: PubSubID,
        messageActionID: PubSubID,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let messageTimetoken = messageID.internalID as? NSNumber else {
            return completion(.failure(Errors.expectedPubSubIDInternalToBeNSNumber))
        }

        guard let actionTimetoken = messageActionID.internalID as? NSNumber else {
            return completion(.failure(Errors.expectedPubSubIDInternalToBeNSNumber))
        }

        pubnub.removeMessageAction()
            .channel(_channel)
            .messageTimetoken(messageTimetoken)
            .actionTimetoken(actionTimetoken)
            .performWithCompletion { status in
                guard !status.isError else {
                    log.error(status.errorData.information)
                    if status.statusCode == 400 {
                        completion(.failure(Errors.messageActionDoesntExist))
                    } else {
                        completion(.failure(Errors.failedToRemoveMessageAction))
                    }
                    return
                }
                self.delegate?.channel(
                    self,
                    messageActionDeleted: messageActionID,
                    messageID: messageID
                )
                completion(.success(true))
        }
    }

    func disconnect(){
        pubnub.removeListener(self)
        pubnub.unsubscribeFromChannels([_channel], withPresence: false)
    }

    func pause() {
        pauseStatus = .paused
        pubnub.removeListener(self)
        pubnub.unsubscribeFromChannels([_channel], withPresence: false)
    }

    func resume() {
        pauseStatus = .unpaused
        pubnub.addListener(self)
        pubnub.subscribeToChannels([_channel], withPresence: false)
    }

    func client(
        _ client: PubNub,
        didReceiveMessage message: PNMessageResult
    ) {
        guard message.data.channel == self._channel else { return }
        guard let messageDict = message.data.message as? [String: AnyObject] else { return }

        let id = PubSubID(message.data.timetoken)
        let pnMessage = PubSubChannelMessage(
            pubsubID: id,
            message: messageDict,
            createdAt: message.data.timetoken,
            messageActions: []
        )
        messageCache[id] = pnMessage
        delegate?.channel(self, messageCreated: pnMessage)
    }

    func client(
        _ client: PubNub,
        didReceiveMessageAction action: PNMessageActionResult
    ) {
        guard action.data.action.uuid != self.pubnub.uuid() else {
            // Ignoring actions received/removed by self because we are processing those earlier
            // in the sendMessageAction and removeMessageAction calls
            return
        }

        switch action.data.event {
        case "removed":
            let messageID = PubSubID(action.data.action.messageTimetoken)
            let actionID = PubSubID(action.data.action.actionTimetoken)
            messageCache[messageID]?.messageActions.removeAll(where: { $0.id == actionID })
            delegate?.channel(self, messageActionDeleted: actionID, messageID: messageID)
        case "added":
            let messageID = PubSubID(action.data.action.messageTimetoken)
            let actionID = PubSubID(action.data.action.actionTimetoken)
            let pnMessageAction = PubSubMessageAction(
                messageID: messageID,
                id: actionID,
                sender: action.data.action.uuid,
                type: action.data.action.type,
                value: action.data.action.value,
                timetoken: action.data.action.actionTimetoken,
                messageTimetoken: action.data.action.messageTimetoken
            )
            messageCache[messageID]?.messageActions.append(pnMessageAction)
            delegate?.channel(self, messageActionCreated: pnMessageAction)
        default:
            log.warning("Unsupported message action event \(action.data.event)")
        }

    }

    func client(
        _ client: PubNub,
        didReceive status: PNStatus
    ) {
        switch status.category {
        case .PNUnexpectedDisconnectCategory:
            log.info("Chat Disconnected")
        case .PNReconnectedCategory:
            log.info("Chat Reconnected")
        default:
            log.dev("status: \(status.category.rawValue)")
        }
    }

    enum Errors: LocalizedError {
        case failedToSerializeHistoryToJsonData
        case pubnubStatusError(errorStatus: PNErrorStatus)
        case foundNoResultsFromHistoryRequest
        case foundNoResultsForChannel(channel: String)
        case messageActionAlreadyAdded
        case messageActionDoesntExist
        case failedToSendMessageAction
        case failedToRemoveMessageAction
        case expectedPubSubIDInternalToBeNSNumber
        case foundNoAction
        case noMessageCountResult
        case noMessageCountForChannel(channel: String)

        var errorDescription: String? {
            switch self {
            case .failedToSerializeHistoryToJsonData:
                return "Failed to serialize the PubNub history result as json data."
            case .pubnubStatusError(let errorStatus):
                return errorStatus.errorData.information
            case .foundNoResultsFromHistoryRequest:
                return "Failed to find results for history request."
            case .foundNoResultsForChannel(let channel):
                return "Didn't find any results for channel \(channel)"
            case .messageActionAlreadyAdded:
                return "Failed to send the message action because it already exists."
            case .messageActionDoesntExist:
                return "Failed to remove the message action because it doesn't exist."
            case .failedToSendMessageAction:
                return "Failed to send the message action."
            case .failedToRemoveMessageAction:
                return "Failed to remove the message action."
            case .expectedPubSubIDInternalToBeNSNumber:
                return "Expected the pub sub id internal to be type NSNumber."
            case .foundNoAction:
                return "Failed to receive an action"
            case .noMessageCountResult:
                return "Message count request returned nil result."
            case .noMessageCountForChannel(let channel):
                return "Message count for channel \(channel) not found in dictionary."
            }
        }
    }
}

extension PNHistoryAPICallBuilder {
    func start(optional start: NSNumber?) -> PNHistoryAPICallBuilder {
        guard let start = start else { return self }
        return self.start(start)
    }

    func end(optional end: NSNumber?) -> PNHistoryAPICallBuilder {
        guard let end = end else { return self }
        return self.end(end)
    }
}

struct PubNubHistoryMessage: Decodable{
    typealias MessageActions = [String: [String: [MessageActionBody]]]
    let actions: MessageActions?
    let timetoken: UInt64
}

struct MessageActionBody: Codable {
    let actionTimetoken: UInt64
    let uuid: String
}
