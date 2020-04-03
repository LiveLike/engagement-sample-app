//
//  PollWidgetVoteClient.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/18/19.
//

import Foundation

protocol PollWidgetVoteClient {
    func setVote(url: URL) -> Promise<WidgetVote>
    func updateVote(url: URL, optionId: String) -> Promise<WidgetVote>
}

protocol PollWidgetResultsClient {
    var didReceivePollResults: ((PollResults) -> Void)? { get set }
    func subscribeToUpdateChannel(_ channel: String)
    func unsubscribeFromUpdateChannel(_ channel: String)
}

class PollClient: PollWidgetResultsClient {
    var didReceivePollResults: ((PollResults) -> Void)?

    private let widgetMessagingClient: WidgetClient
    private let accessToken: AccessToken

    init(widgetMessagingClient: WidgetClient, accessToken: AccessToken) {
        self.widgetMessagingClient = widgetMessagingClient
        self.accessToken = accessToken
    }

    func subscribeToUpdateChannel(_ channel: String) {
        widgetMessagingClient.addListener(self, toChannel: channel)
    }

    func unsubscribeFromUpdateChannel(_ channel: String) {
        widgetMessagingClient.removeListener(self, fromChannel: channel)
    }
}

extension PollClient: PollWidgetVoteClient {
    func setVote(url: URL) -> Promise<WidgetVote> {
        let resource = Resource<WidgetVote>(url: url, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }

    func updateVote(url: URL, optionId: String) -> Promise<WidgetVote> {
        let voteBody = VoteBody(optionId: optionId)
        let resource = Resource<WidgetVote>(url: url, method: .patch(voteBody), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}

extension PollClient: WidgetProxyInput {
    func publish(event: ClientEvent) {
        guard case let .imagePollResults(results) = event else {
            log.error("Received event \(event.description) in PollWidgetLiveUpdateClient when only .imagePollResults were expected.")
            return
        }

        DispatchQueue.main.sync { [weak self] in
            self?.didReceivePollResults?(results)
        }
    }

    func discard(event: ClientEvent, reason: DiscardedReason) {}

    func connectionStatusDidChange(_ status: ConnectionStatus) {}

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
}
