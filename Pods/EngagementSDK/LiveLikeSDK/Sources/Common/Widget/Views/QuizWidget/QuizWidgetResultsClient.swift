//
//  QuizWidgetResultsClient.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import Foundation

protocol QuizWidgetResultsClient {
    var didReceiveResults: ((QuizResults) -> Void)? { get set }
    func subscribe()
    func unsubscribe()
}

protocol QuizWidgetVoteClient {
    func vote(url: URL) -> Promise<QuizVote>
    func vote(url: URL, completion: @escaping (Result<QuizVote, Error>) -> Void)
}
