//
//  ImageSliderClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import Foundation

class ImageSliderClient: ImageSliderResultsClient {
    weak var delegate: ImageSliderResultsDelegate? {
        didSet {
            if delegate != nil {
                widgetMessagingClient.addListener(self, toChannel: updateChannel)
            } else {
                widgetMessagingClient.removeListener(self, fromChannel: updateChannel)
            }
        }
    }

    private let widgetMessagingClient: WidgetClient
    private let updateChannel: String
    private let accessToken: AccessToken

    init(widgetMessagingClient: WidgetClient, updateChannel: String, accessToken: AccessToken) {
        self.widgetMessagingClient = widgetMessagingClient
        self.updateChannel = updateChannel
        self.accessToken = accessToken
    }
}

extension ImageSliderClient: WidgetProxyInput {
    func publish(event: ClientEvent) {
        switch event {
        case let .imageSliderResults(results):
            DispatchQueue.main.sync { [weak self] in
                self?.delegate?.resultsClient(didReceiveResults: results)
            }
        default:
            log.error("Received event \(event.description) in ImageSliderLiveResultsClient when only .imageSliderResults were expected.")
        }
    }

    func discard(event: ClientEvent, reason: DiscardedReason) {}

    func connectionStatusDidChange(_ status: ConnectionStatus) {}

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
}

extension ImageSliderClient: ImageSliderVoteClient {
    func vote(url: URL, magnitude: Float) -> Promise<ImageSliderVoteResponse> {
        let magnitudeString = String(format: "%.3f", magnitude) // Server expects <= 3 decimal places
        let vote = ImageSliderVote(magnitude: magnitudeString)
        let resource = Resource<ImageSliderVoteResponse>(url: url, method: .post(vote), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}
