//
//  QuizWidget.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import Foundation

typealias QuizWidgetView = QuizWidget & ChoiceWidgetView

protocol QuizWidget {
    var didSelectChoice: ((QuizSelection) -> Void)? { get set }
    func beginTimer(seconds: TimeInterval, completion: @escaping () -> Void)
    func showCloseButton(completion: @escaping () -> Void)
    func revealAnswer(myOptionId: String?, completion: (() -> Void)?)
    func updateResults(_ results: QuizResults)
    func lockSelection()
    func stopAnswerRevealAnimation()
}
