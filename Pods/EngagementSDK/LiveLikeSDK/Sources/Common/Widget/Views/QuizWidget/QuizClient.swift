//
//  QuizClient.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/22/19.
//

import Foundation

class QuizClient: QuizWidgetResultsClient {
    var didReceiveResults: ((QuizResults) -> Void)?

    private let widgetMessagingClient: WidgetClient
    private let updateChannel: String
    private let accessToken: AccessToken

    init(widgetMessagingClient: WidgetClient, updateChannel: String, accessToken: AccessToken) {
        self.widgetMessagingClient = widgetMessagingClient
        self.updateChannel = updateChannel
        self.accessToken = accessToken
    }

    func subscribe() {
        widgetMessagingClient.addListener(self, toChannel: updateChannel)
    }

    func unsubscribe() {
        widgetMessagingClient.removeListener(self, fromChannel: updateChannel)
    }
}

extension QuizClient: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case let .textQuizResults(results), let .imageQuizResults(results):
            DispatchQueue.main.sync { [weak self] in
                self?.didReceiveResults?(results)
            }
        default:
            log.error("Received event \(event.clientEvent.description) in QuizWidgetLiveResultsClient when only .textQuizResults were expected.")
        }
    }

    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
}

extension QuizClient: QuizWidgetVoteClient {
    func vote(url: URL) -> Promise<QuizVote> {
        let resource = Resource<QuizVote>(url: url, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    func vote(
        url: URL,
        completion: @escaping (Result<QuizVote, Error>) -> Void
    ) {
        self.vote(url: url).then { quizVote in
            completion(.success(quizVote))
        }.catch { error in
            completion(.failure(error))
        }
    }
}
