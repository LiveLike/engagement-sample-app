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
        oldestMessageDate: Date?,
        newestMessageDate: Date?,
        limit: UInt,
        completion: @escaping (Result<PubSubHistoryResult, Error>) -> Void
    ) {

        let startValue: NSNumber? = {
            guard let date = newestMessageDate else { return nil }
            return NSNumber(value: Int64(date.timeIntervalSince1970))
        }()

        let endValue: NSNumber? = {
            guard let date = oldestMessageDate else { return nil }
            return NSNumber(value: Int64(date.timeIntervalSince1970 + 1))
        }()

        self.pubnub.historyForChannel(
            channel,
            start: startValue,
            end: endValue,
            limit: limit,
            reverse: false,
            includeTimeToken: true
        ) { (result, status) in
            // TODO: use better errors
            if let status = status {
                if status.isError {
                    return
                }
            }
            guard let result = result else {
                // No reject
                return
            }

            let decoder: JSONDecoder = {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
                return decoder
            }()

            guard let channelResults = result.data.channels[channel] else {
                return
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

                guard let history = try? decoder.decode(PubNubHistoryMessage.self, from: historyData) else {
                    log.error("Failed to decode historyData as PubNubHistoryMessage.")
                    return nil
                }

                guard let messageDict = historyMessageDict["message"] as? [String: Any] else {
                    log.error("Failed to find 'message' value from historyMessageDict.")
                    return nil
                }

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
            }

            completion(
                .success(
                    PubSubHistoryResult(
                        newestMessageTimetoken: Date(timeIntervalSince1970: TimeInterval(truncating: result.data.end)),
                        oldestMessageTimetoken: Date(timeIntervalSince1970: TimeInterval(truncating: result.data.start)),
                        messages: chatMessages
                    )
                )
            )
        }
    }

    enum Errors: LocalizedError {
        case failedToParseHistoryResultAsJsonData

        var errorDescription: String? {
            switch self {
            case .failedToParseHistoryResultAsJsonData:
                return "Failed to parse the history result as json data."
            }
        }
    }
}
