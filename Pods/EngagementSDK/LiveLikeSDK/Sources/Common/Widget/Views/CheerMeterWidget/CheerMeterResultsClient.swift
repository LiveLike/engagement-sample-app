//
//  CheerMeterResultsClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/2/20.
//

import Foundation

class LiveCheerMeterResultsClient: CheerMeterResultsClient {
    weak var delegate: CheerMeterResultsDelegate?
    var latestResults: CheerMeterResults?
    
    private let widgetClient: WidgetClient
    private let subscribeChannel: String
    
    init(
        widgetClient: WidgetClient,
        subscribeChannel: String
    ) {
        self.widgetClient = widgetClient
        self.subscribeChannel = subscribeChannel
        
        widgetClient.addListener(self, toChannel: subscribeChannel)
    }
}

extension LiveCheerMeterResultsClient: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        guard case let .cheerMeterResults(payload) = event.clientEvent else {
            return
        }
        DispatchQueue.main.sync {
            self.latestResults = payload
            delegate?.didReceiveResults(payload)
        }
    }

    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}
    func error(_ error: Error) {}
}
