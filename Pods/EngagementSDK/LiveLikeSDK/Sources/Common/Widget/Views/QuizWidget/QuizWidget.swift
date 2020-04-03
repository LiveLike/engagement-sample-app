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
    func beginTimer(completion: @escaping () -> Void)
    func beginCloseTimer(duration: Double, completion: @escaping (DismissAction) -> Void)
    func revealAnswer(myOptionId: String?)
    func updateResults(_ results: QuizResults)
    func lockSelection()
}
