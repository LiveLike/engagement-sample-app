//
//  MessagingClient.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-21.
//

import Foundation

protocol WidgetClient: AnyObject {
    /// An instance `ChannelListeners` to manage channel listeners
    var widgetListeners: ChannelListeners { get }
    /// Add a listener for a specific channel
    ///
    /// - Parameters:
    ///   - listener: the `WidgetProxyInput` that will receive `channel` events
    ///   - channel: channel name on which client should try to subscribe
    func addListener(_ listener: WidgetProxyInput, toChannel channel: String)

    /// Remove a listener for a specific channel
    ///
    /// - Parameters:
    ///   - listener: the `WidgetProxyInput` that will receive `channel` events
    ///   - channel: channel name on which client should try to subscribe
    func removeListener(_ listener: WidgetProxyInput, fromChannel channel: String)

    func unsubscribe(fromChannel channel: String)

    /// Unsubscribe from all channels
    func removeAllListeners()
}

/// Interface description for classes which would like to be registered for events from `MessagingClient`
protocol MessagingClientEventListener: AnyObject {
    /// Notify delegate about new message which arrived from one of the channels
    /// on which the client is currently subscribed
    ///
    /// - Parameters:
    ///   - client: `MessagingClient` which triggered this callback
    ///   - message: `ClientMessage` instance containing message information
    ///   - channel: Name of channel for which subscriber received data.
    func client(_ client: WidgetClient, didReceiveMessage message: ClientEvent, channel: String)

    /// Notify delegate that a message did arrived from one of the channels
    /// on which the client is currently subscribed, however it encountered an error
    ///
    /// - Parameters:
    ///   - client: `MessagingClient` which triggered this callback
    ///   - error: `Error` as a result of the `ClientEvent` failing
    ///   - channel: Name of channel for which subscriber received data.
    func client(_ client: WidgetClient, didReceiveMessageError error: Error, channel: String)

    /// Notify delegate about subscription state changes.
    ///
    /// This callback can fire when client tried to subscribe on channels for which it doesn't
    /// have access rights or when network went down and client unexpectedly disconnected.
    ///
    /// - Parameters:
    ///   - client: `MessagingClient` which triggered this callback
    ///   - status: `ConnectionStatus` instance containing connection status
    func client(_ client: WidgetClient, didReceiveStatus status: ConnectionStatus)
}

// MARK: - WidgetMessagingEventListener

// Create default implementation of `MessagingClientEventListener`
extension MessagingClientEventListener {
    func client(_ client: WidgetClient, didReceiveMessage message: ClientEvent, channel: String) {
        log.info("Message: \(message) Channel: \(channel)")
    }

    func client(_ client: WidgetClient, didReceiveMessageError error: Error, channel: String) {
        log.error("Error: \(error) for channel: \(channel)")
    }

    func client(_ client: WidgetClient, didReceiveStatus status: ConnectionStatus) {
        log.info("Status: \(status)")
    }
}
