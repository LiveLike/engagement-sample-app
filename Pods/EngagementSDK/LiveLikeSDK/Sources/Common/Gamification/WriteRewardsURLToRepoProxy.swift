//
//  WriteRewardsURLToRepoProxy.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/9/19.
//

import Foundation

class WriteRewardsURLToRepoProxy {
    private let rewardsURLRepo: RewardsURLRepo

    var downStreamProxyInput: WidgetProxyInput?

    init(rewardsURLRepo: RewardsURLRepo) {
        self.rewardsURLRepo = rewardsURLRepo
    }
}

extension WriteRewardsURLToRepoProxy: WidgetProxy {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case .widget(let widget):
            switch widget {
                case let .textPollCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .textQuizCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .textPredictionCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .textPredictionFollowUp(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .imagePredictionCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .imagePredictionFollowUp(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .imagePollCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .alertCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .imageQuizCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .imageSliderCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
                case let .cheerMeterCreated(payload):
                    add(id: payload.id, url: payload.rewardsUrl)
            }
        default:
            break
        }

        downStreamProxyInput?.publish(event: event)
    }

    private func add(id: String, url: URL?) {
        guard let url = url else { return }
        rewardsURLRepo.add(withID: id, rewardsURL: url)
    }
}
