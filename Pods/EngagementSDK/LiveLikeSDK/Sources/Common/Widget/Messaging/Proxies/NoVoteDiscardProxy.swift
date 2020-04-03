//
//  NoVoteDiscardProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 4/1/19.
//

import Foundation

// Discards widgets if a previous vote is required but does not exist
class NoVoteDiscardProxy: WidgetProxy {
    var downStreamProxyInput: WidgetProxyInput?

    private let voteRepo: WidgetVotes

    init(voteRepo: WidgetVotes) {
        self.voteRepo = voteRepo
    }

    func publish(event: ClientEvent) {
        switch event {
        case let .textPredictionFollowUp(payload, _):
            guard let vote = voteRepo.findVote(for: payload.id) else {
                downStreamProxyInput?.discard(event: event, reason: .noVote)
                break
            }
            voteRepo.clearVote(for: payload.id)
            downStreamProxyInput?.publish(event: .textPredictionFollowUp(payload, vote))
        case let .imagePredictionFollowUp(payload, _):
            guard let vote = voteRepo.findVote(for: payload.id) else {
                downStreamProxyInput?.discard(event: event, reason: .noVote)
                break
            }
            voteRepo.clearVote(for: payload.id)
            downStreamProxyInput?.publish(event: .imagePredictionFollowUp(payload, vote))
        default:
            downStreamProxyInput?.publish(event: event)
        }
    }
}
