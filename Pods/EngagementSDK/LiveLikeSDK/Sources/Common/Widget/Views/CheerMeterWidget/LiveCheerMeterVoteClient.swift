//
//  CheerMeterVoteClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/21/19.
//

import Foundation

/**
 Sends votes after the batch threshold is reached or after no vote submitted within the debounceTimeInterval
 */
class LiveCheerMeterVoteClient: CheerMeterVoteClient {
    private let batchThreshold: Int = 10
    private let debounceTimeInterval: TimeInterval = 1

    private weak var delegate: CheerMeterVoteClientDelegate?

    private let widgetMessagingClient: WidgetClient
    private let subscribeChannel: String
    private let voteDebouncer: Debouncer<(voteURL: URL, voteCount: Int)>
    private let accessToken: AccessToken
    private var batchedVotes: Int = 0

    init(widgetMessagingClient: WidgetClient, subscribeChannel: String, accessToken: AccessToken) {
        self.widgetMessagingClient = widgetMessagingClient
        self.subscribeChannel = subscribeChannel
        self.accessToken = accessToken
        voteDebouncer = Debouncer(delay: debounceTimeInterval)
        voteDebouncer.callback = { [weak self] voteCountAndURL in
            self?.voteAndResetBatchedVotes(voteURL: voteCountAndURL.voteURL, voteCount: voteCountAndURL.voteCount)
        }
    }

    func setDelegate(_ delegate: CheerMeterVoteClientDelegate) {
        self.delegate = delegate
        widgetMessagingClient.addListener(self, toChannel: subscribeChannel)
    }

    func removeDelegate(_ delegate: CheerMeterVoteClientDelegate) {
        self.delegate = nil
        widgetMessagingClient.removeListener(self, fromChannel: subscribeChannel)
    }

    func sendVote(voteURL: URL) {
        batchedVotes += 1
        if batchedVotes >= batchThreshold {
            voteAndResetBatchedVotes(voteURL: voteURL, voteCount: batchedVotes)
        } else {
            voteDebouncer.call(value: (voteURL, batchedVotes))
        }
    }

    private func postVote(url: URL, voteCount: Int) -> Promise<CheerMeterVoteResponse> {
        let vote = CheerMeterVote(voteCount: voteCount)
        let resource = Resource<CheerMeterVoteResponse>(url: url, method: .post(vote), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }

    private func voteAndResetBatchedVotes(voteURL: URL, voteCount: Int) {
        log.verbose("Sending Cheer Meter vote with \(voteCount)")
        postVote(url: voteURL, voteCount: voteCount).then { _ in
            log.verbose("Successfully submitted Cheer Meter vote.")
        }.catch { _ in
            log.error("Failed to submit Cheer Meter vote.")
        }
        batchedVotes = 0
    }
}

private struct CheerMeterVote: Codable {
    let voteCount: Int
}

private struct CheerMeterVoteResponse: Decodable {}

extension LiveCheerMeterVoteClient: WidgetProxyInput {
    func publish(event: ClientEvent) {
        guard case let .cheerMeterResults(payload) = event else {
            return
        }
        DispatchQueue.main.sync {
            delegate?.didReceiveResults(payload)
        }
    }

    func discard(event: ClientEvent, reason: DiscardedReason) {
        //
    }

    func connectionStatusDidChange(_ status: ConnectionStatus) {
        //
    }

    func error(_ error: Error) {
        //
    }
}

protocol CheerMeterVoteClient {
    func setDelegate(_ delegate: CheerMeterVoteClientDelegate)
    func removeDelegate(_ delegate: CheerMeterVoteClientDelegate)
    func sendVote(voteURL: URL)
}

protocol CheerMeterVoteClientDelegate: AnyObject {
    func didReceiveResults(_ results: CheerMeterResults)
}
