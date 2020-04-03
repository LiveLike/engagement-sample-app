//
//  ImagePollWidgetView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/20/19.
//

import UIKit

typealias PollWidgetView = PollWidget & ChoiceWidgetView
typealias PollSelection = (id: String, url: URL)

protocol PollWidget {
    var onSelectionAction: ((PollSelection) -> Void)? { get set }
    func beginTimer(completion: @escaping () -> Void)
    func beginCloseTimer(duration: Double, closeAction: @escaping (DismissAction) -> Void)
    func lockSelections()
    func revealResults()
    func updateResults(results: PollResults)
}
