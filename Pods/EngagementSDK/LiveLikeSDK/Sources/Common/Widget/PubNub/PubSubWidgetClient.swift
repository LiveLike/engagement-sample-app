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

    init(subscribeKey: String, origin: String?) {
        self.subscribeKey = subscribeKey
        let config = PNConfiguration(publishKey: "", subscribeKey: subscribeKey)
        if let origin = origin {
            config.origin = origin
        }
        config.keepTimeTokenOnListChange = false
        config.catchUpOnSubscriptionRestore = false
        config.completeRequestsBeforeSuspension = false
        client = PubNub.clientWithConfiguration(config, callbackQueue: messagingSerialQueue)
        super.init()
        client.addListener(self)
    }

    func addListener(_ listener: WidgetProxyInput, toChannel channel: String) {
        client.subscribeToChannels([channel], withPresence: false)
        log.debug("[PubNub] Connected to PubNub channel. Connected to \(client.channels().count) channels.")
        widgetListeners.addListener(listener, forChannel: channel)
    }

    func removeListener(_ listener: WidgetProxyInput, fromChannel channel: String) {
        widgetListeners.removeListener(listener, forChannel: channel)
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
    func processMessage(message: PNMessageResult) throws -> MessagingEventType {
        let eventName = try extractEventNameFromPubNubMessage(message: message)
        let jsonData = try extractWidgetPayloadFromPubNubMessage(message: message)
        return try parsePayload(for: eventName, jsonObject: jsonData)
    }
    
    func extractEventNameFromPubNubMessage(message: PNMessageResult) throws -> EventName {
        guard let message = message.data.message as? [String: AnyObject] else { throw MessagingClientError.invalidEvent(event: "The message is empty") }
        guard let eventString = message["event"] as? String else { throw MessagingClientError.invalidEvent(event: "The message does not contain an event") }
        guard let eventType = EventName(rawValue: eventString) else { throw MessagingClientError.invalidEvent(event: "The message has an invalid event \(eventString)") }
        return eventType
    }
    
    func extractWidgetPayloadFromPubNubMessage(message: PNMessageResult) throws -> Any {
        guard let message = message.data.message as? [String: AnyObject] else { throw MessagingClientError.invalidEvent(event: "The message is empty") }
        guard let payload = message["payload"] as? [String: AnyObject] else { throw MessagingClientError.invalidEvent(event: "The message does not contain a payload") }
//        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        return payload
    }

    // swiftlint:disable:next function_body_length
    func parsePayload(for event: EventName, jsonObject: Any) throws -> MessagingEventType {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        switch event {
        case .textPredictionCreated:
            let textPrediction = try decoder.decode(TextPredictionCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textPredictionCreated(textPrediction)
            return MessagingEventType.widget(clientEvent)
        case .textPredictionFollowUpCreated:
            let textPredictionFollowUp = try decoder.decode(TextPredictionFollowUp.self, from: jsonData)
            let clientEvent = ClientEvent.textPredictionFollowUp(textPredictionFollowUp)
            return MessagingEventType.widget(clientEvent)
        case .imagePredictionCreated:
            let imagePrediction = try decoder.decode(ImagePredictionCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imagePredictionCreated(imagePrediction)
            return MessagingEventType.widget(clientEvent)
        case .imagePredictionFollowUpCreated:
            let imagePredictionFollowUp = try decoder.decode(ImagePredictionFollowUp.self, from: jsonData)
            let clientEvent = ClientEvent.imagePredictionFollowUp(imagePredictionFollowUp)
            return MessagingEventType.widget(clientEvent)
        case .textPredictionResults, .imagePredictionResults:
            let predictionResults = try decoder.decode(PredictionResults.self, from: jsonData)
            let clientEvent = ClientEvent.textPredictionResults(predictionResults)
            return MessagingEventType.widget(clientEvent)
        case .imagePollCreated:
            let imagePollCreated = try decoder.decode(ImagePollCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imagePollCreated(imagePollCreated)
            return MessagingEventType.widget(clientEvent)
        case .imagePollResults, .textPollResults:
            let pollResults = try decoder.decode(PollResults.self, from: jsonData)
            let clientEvent = ClientEvent.imagePollResults(pollResults)
            return MessagingEventType.widget(clientEvent)
        case .textPollCreated:
            let textPollCreated = try decoder.decode(TextPollCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textPollCreated(textPollCreated)
            return MessagingEventType.widget(clientEvent)
        case .alertCreated:
            let alertCreated = try decoder.decode(AlertCreated.self, from: jsonData)
            let clientEvent = ClientEvent.alertCreated(alertCreated)
            return MessagingEventType.widget(clientEvent)
        case .textQuizCreated:
            let textQuizCreated = try decoder.decode(TextQuizCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textQuizCreated(textQuizCreated)
            return MessagingEventType.widget(clientEvent)
        case .textQuizResults:
            let quizResults = try decoder.decode(QuizResults.self, from: jsonData)
            let clientEvent = ClientEvent.textQuizResults(quizResults)
            return MessagingEventType.widget(clientEvent)
        case .imageQuizCreated:
            let imageQuizCreated = try decoder.decode(ImageQuizCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imageQuizCreated(imageQuizCreated)
            return MessagingEventType.widget(clientEvent)
        case .imageQuizResults:
            let quizResults = try decoder.decode(QuizResults.self, from: jsonData)
            let clientEvent = ClientEvent.imageQuizResults(quizResults)
            return MessagingEventType.widget(clientEvent)
        case .imageSliderCreated:
            let imageSliderCreated = try decoder.decode(ImageSliderCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imageSliderCreated(imageSliderCreated)
            return MessagingEventType.widget(clientEvent)
        case .imageSliderResults:
            let imageSliderResults = try decoder.decode(ImageSliderResults.self, from: jsonData)
            let clientEvent = ClientEvent.imageSliderResults(imageSliderResults)
            return MessagingEventType.widget(clientEvent)
        case .cheerMeterCreated:
            let cheerMeterCreated = try decoder.decode(CheerMeterCreated.self, from: jsonData)
            let clientEvent = ClientEvent.cheerMeterCreated(cheerMeterCreated)
            return .widget(clientEvent)
        case .cheerMeterResults:
            let cheerMeterResults = try decoder.decode(CheerMeterResults.self, from: jsonData)
            let clientEvent = ClientEvent.cheerMeterResults(cheerMeterResults)
            return .widget(clientEvent)
        }
    }
}

extension PubSubWidgetClient: PNObjectEventListener {
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        do {
            let eventName = try extractEventNameFromPubNubMessage(message: message)
            let payloadData = try extractWidgetPayloadFromPubNubMessage(message: message)
            let clientEvent = try parsePayload(for: eventName, jsonObject: payloadData)
            
            switch clientEvent {
            case let .widget(widgetEvent):
                widgetListeners.publish(channel: message.data.channel) {
                    $0.publish(event: WidgetProxyPublishData(clientEvent: widgetEvent, jsonObject: payloadData))
                }
            }
        } catch {
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
