//
//  MockQuizWidgetResultsClients.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import Foundation

class MockQuizWidgetResultsClient: QuizWidgetResultsClient, QuizWidgetVoteClient {
    func vote(url: URL) -> Promise<QuizVote> {
        return Promise()
    }

    var didReceiveResults: ((QuizResults) -> Void)?

    private var lastResults: QuizResults

    private var timer: DispatchSourceTimer?

    init(textQuizCreated: TextQuizCreated) {
        let results = textQuizCreated.choices.map { choice in
            QuizResult(id: choice.id, isCorrect: choice.isCorrect, answerCount: 0)
        }
        lastResults = QuizResults(choices: results)
    }

    init(imageQuizCreated: ImageQuizCreated) {
        let results = imageQuizCreated.choices.map { choice in
            QuizResult(id: choice.id, isCorrect: choice.isCorrect, answerCount: 0)
        }
        lastResults = QuizResults(choices: results)
    }

    func subscribe() {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            // generate random results - skew toward correct options
            for index in 0 ..< self.lastResults.choices.count {
                let correctMultiplier = self.lastResults.choices[index].isCorrect ? 3 : 1
                self.lastResults.choices[index].answerCount += Int.random(in: 0 ... 20) * correctMultiplier
            }

            DispatchQueue.main.sync {
                self.didReceiveResults?(self.lastResults)
            }
        }
        timer?.resume()
    }

    func unsubscribe() {
        timer?.cancel()
        timer = nil
    }
}
