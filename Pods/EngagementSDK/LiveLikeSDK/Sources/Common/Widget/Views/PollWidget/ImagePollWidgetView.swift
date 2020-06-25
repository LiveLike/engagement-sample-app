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
    func beginTimer(seconds: TimeInterval, completion: @escaping () -> Void)
    func setOptionsLocked(_ lock: Bool)
    func revealResults()
    func updateResults(results: PollResults)
    func showCloseButton(completion: @escaping () -> Void)
}
