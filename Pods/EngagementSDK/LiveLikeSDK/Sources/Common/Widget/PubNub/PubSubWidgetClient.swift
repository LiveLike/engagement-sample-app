//
//  MessagingServiceAPI.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-21.
//

import PubNub
import UIKit

/// Concrete implementation of `WidgetMessagingClient`
/// based on [PubNub](https://www.pubnub.com/docs/ios-objective-c/pubnub-objective-c-sdk)
class PubSubWidgetClient: NSObject, WidgetClient {
    /// Internal
    var widgetListeners = ChannelListeners()
    /// Private
    private var client: PubNub
    private let subscribeKey: String
    /// The `DispatchQueue` onto which the client will receive and dispatch events.
    private let messagingSerialQueue = DispatchQueue(label: "com.livelike.pubnub")

    init(subscribeKey: String, origin: String?, userID: String) {
        self.subscribeKey = subscribeKey
        let config = PNConfiguration(publishKey: "", subscribeKey: subscribeKey)
        if let origin = origin {
            config.origin = origin
        }
        config.keepTimeTokenOnListChange = false
        config.catchUpOnSubscriptionRestore = false
        config.completeRequestsBeforeSuspension = false
        config.uuid = userID
        client = PubNub.clientWithConfiguration(config, callbackQueue: messagingSerialQueue)
        super.init()
        client.addListener(self)
    }

    func addListener(_ listener: WidgetProxyInput, toChannel channel: String) {
        widgetListeners.addListener(listener, forChannel: channel)
        client.subscribeToChannels([channel], withPresence: false)
        log.debug("[PubNub] Connected to PubNub channel. Connected to \(client.channels().count) channels.")
    }

    func removeListener(_ listener: WidgetProxyInput, fromChannel channel: String) {
        widgetListeners.removeListener(listener, forChannel: channel)
        unsubscribe(fromChannel: channel)
    }

    /// Unsubscribes from a channel if there are no more listeners
    func unsubscribe(fromChannel channel: String) {
        if widgetListeners.isEmpty(forChannel: channel) {
            client.unsubscribeFromChannels([channel], withPresence: false)
            log.debug("[PubNub] Disconnected from PubNub channel. Connected to \(client.channels().count) channels.")
        }
    }

    func removeAllListeners() {
        widgetListeners.removeAll()
        client.unsubscribeFromAll()
    }
}

private extension PubSubWidgetClient {
    /// We are expecting all messages to have the following schema
    ///
    /// ```
    ///    {
    ///      event = "the_event_name" // predefined `EventName`
    ///      payload = {
    ///       ...
    ///      }
    ///    }
    /// ```
    func processMessage(message: PNMessageResult) throws -> ClientEvent {
        guard let message = message.data.message as? [String: AnyObject] else {
            throw MessagingClientError.invalidEvent(event: "The message is empty")
        }
        let jsonData = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return try decoder.decode(ClientEvent.self, from: jsonData)
    }
}

extension PubSubWidgetClient: PNObjectEventListener {
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        do {
            let clientEvent = try processMessage(message: message)
            widgetListeners.publish(channel: message.data.channel) {
                $0.publish(event: WidgetProxyPublishData(clientEvent: clientEvent))
            }
        } catch {
            log.error(error)
            widgetListeners.publish(channel: message.data.channel) { $0.error(error) }
        }
    }

    func client(_ client: PubNub, didReceive status: PNStatus) {
        if status.isError {
            let status = ConnectionStatus.error(description: status.stringifiedCategory())
            widgetListeners.publish(channel: nil) { $0.connectionStatusDidChange(status) }
        } else {
            let status = ConnectionStatus.connected(description: status.stringifiedCategory())
            widgetListeners.publish(channel: nil) { $0.connectionStatusDidChange(status) }
        }
    }
}
