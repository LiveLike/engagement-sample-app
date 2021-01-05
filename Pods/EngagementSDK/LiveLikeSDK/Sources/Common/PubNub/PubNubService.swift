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
}
