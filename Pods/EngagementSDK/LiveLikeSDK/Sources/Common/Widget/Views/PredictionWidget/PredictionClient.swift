//
//  PredictionClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/12/19.
//

import Foundation

protocol PredictionVoteClient: AnyObject {
    var didRecieveResults: ((PredictionResults) -> Void)? { get set }
    func vote(url: URL) -> Promise<WidgetVote>
}

class PredictionClient: PredictionVoteClient, WidgetProxyInput {
    
    private let accessToken: AccessToken

    var didRecieveResults: ((PredictionResults) -> Void)?
    
    init(accessToken: AccessToken, widgetClient: WidgetClient, resultsChannel: String) {
        self.accessToken = accessToken
        
        widgetClient.addListener(self, toChannel: resultsChannel)
    }

    func vote(url: URL) -> Promise<WidgetVote> {
        let resource = Resource<WidgetVote>(url: url, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    // MARK: Widget Proxy Input
    
    func publish(event: ClientEvent) {
        switch event{
        case .textPredictionResults(let results),
             .imagePredictionResults(let results):
            didRecieveResults?(results)
        default:
            log.error("Unexpected message payload on this channel.")
        }
    }
    
    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
    
    // Not implemented
    func discard(event: ClientEvent, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}
    
}
