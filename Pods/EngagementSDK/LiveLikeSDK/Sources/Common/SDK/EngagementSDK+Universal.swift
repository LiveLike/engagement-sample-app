//
//  LiveLikeSDK+Universal.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-29.
//

import Foundation

extension EngagementSDK: WidgetMessagingClientFactory {
    func widgetMessagingClient(subcribeKey: String, origin: String?) -> WidgetClient & SyncMessagingClient {
        return PubSubWidgetClient(subscribeKey: subcribeKey, origin: origin)
    }
}

extension EngagementSDK {
    func chatMessagingClient(
        appConfig: ApplicationConfiguration,
        userID: ChatUser.ID,
        nickname: UserNicknameVendor,
        accessToken: AccessToken
    ) -> PubSubService? {
        guard
            let subscribeKey = appConfig.pubnubSubscribeKey
        else {
            log.error("Chat Service failed to initialize due to missing subscribe key")
            assertionFailure("Pubnub failed to init because `subscribeKey` is nil")
            return nil
        }

        return PubNubService(
            publishKey: appConfig.pubnubPublishKey,
            subscribeKey: subscribeKey,
            authKey: accessToken.asString,
            origin: appConfig.pubnubOrigin,
            userID: userID
        )
    }
}
