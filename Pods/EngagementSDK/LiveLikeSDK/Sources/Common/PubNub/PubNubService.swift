//
//  PubNubService.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/25/19.
//

import PubNub
import Foundation

class PubNubService: PubSubService {
    private let messagingSerialQueue = DispatchQueue(label: "com.livelike.pubnub.chat")
    private let pubnub: PubNub

    init(
        publishKey: String?,
        subscribeKey: String,
        authKey: String,
        origin: String?,
        userID: ChatUser.ID
    ) {
        let config = PNConfiguration(
            publishKey: publishKey ?? "",
            subscribeKey: subscribeKey
        )
        
        // only apply Auth key when we have a publish key
        if publishKey != nil {
            config.authKey = authKey
            config.uuid = userID.asString
        }
        
        if let origin = origin {
            config.origin = origin
        }
                
        config.completeRequestsBeforeSuspension = false
        
        pubnub = PubNub.clientWithConfiguration(
            config,
            callbackQueue: messagingSerialQueue
        )

        pubnub.filterExpression = "!(content_filter LIKE '*filtered*') || sender_id == '\(userID.asString)'"
    }
    

    func subscribe(_ channel: String) -> PubSubChannel {
        return PubNubChannel(
            pubnub: self.pubnub,
            channel: channel,
            includeTimeToken: true,
            includeMessageActions: true
        )
    }

    func fetchHistory(
        channel: String,
        oldestMessageDate: TimeToken?,
        newestMessageDate: TimeToken?,
        limit: UInt,
        completion: @escaping (Result<PubSubHistoryResult, Error>) -> Void
    ) {
         self.pubnub.history()
            .channel(channel)
            .start(optional: oldestMessageDate?.pubnubTimetoken)
            .end(optional: newestMessageDate?.pubnubTimetoken)
            .limit(limit)
            .reverse(false)
            .includeTimeToken(true)
            .includeMessageActions(true)
            .performWithCompletion { (result, status) in
                if let status = status {
                    if status.isError {
                        //completion(.failure(Errors.pubnubStatusError(errorStatus: status)))
                        return
                    }
                }
                guard let result = result else {
                    //completion(.failure(Errors.foundNoResultsFromHistoryRequest))
                    return
                }

                let decoder: JSONDecoder = {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
                    return decoder
                }()

                guard let channelResults = result.data.channels[channel] else {
                    return //completion(.failure(Errors.foundNoResultsForChannel(channel: self._channel)))
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

    enum Errors: LocalizedError {
        case failedToParseHistoryResultAsJsonData
        case pubnubStatusError(errorStatus: PNErrorStatus)

        var errorDescription: String? {
            switch self {
            case .failedToParseHistoryResultAsJsonData:
                return "Failed to parse the history result as json data."
            case .pubnubStatusError(let errorStatus):
                return errorStatus.errorData.information
            }
        }
    }
}
