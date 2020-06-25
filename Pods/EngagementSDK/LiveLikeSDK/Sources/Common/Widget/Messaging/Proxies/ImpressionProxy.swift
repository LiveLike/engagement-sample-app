//
//  ImpressionProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/28/19.
//

import Foundation

class ImpressionProxy: WidgetProxy {
    var downStreamProxyInput: WidgetProxyInput?

    private let userSessionId: String
    private let accessToken: AccessToken

    init(userSessionId: String, accessToken: AccessToken) {
        self.userSessionId = userSessionId
        self.accessToken = accessToken
    }

    func publish(event: WidgetProxyPublishData) {
        var impressionUrl: URL?

        switch event.clientEvent {
        case let .textPredictionCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .textPredictionFollowUp(payload):
            impressionUrl = payload.impressionUrl
        case let .imagePredictionCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .imagePredictionFollowUp(payload):
            impressionUrl = payload.impressionUrl
        case let .imagePollCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .textPollCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .textQuizCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .imageQuizCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .imageSliderCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .cheerMeterCreated(payload):
            impressionUrl = payload.impressionUrl
        case let .alertCreated(payload):
            impressionUrl = payload.impressionUrl
        case .imagePollResults,
             .textQuizResults,
             .imageQuizResults,
             .imageSliderResults,
             .cheerMeterResults,
             .textPredictionResults,
             .imagePredictionResults,
             .pointsTutorial,
             .badgeCollect:
            break
        }

        if let impressionUrl = impressionUrl {
            setImpression(url: impressionUrl, sessionId: userSessionId).then { _ in
                log.debug("Successfully sent widget impression.")
            }.catch { error in
                log.error("Unable to send impression: \(error)")
            }
        }

        downStreamProxyInput?.publish(event: event)
    }

    private func setImpression(url: URL, sessionId: String) -> Promise<ImpressionResponse> {
        let resource = Resource<ImpressionResponse>(url: url, method: .post(ImpressionBody(sessionId: sessionId)), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}
