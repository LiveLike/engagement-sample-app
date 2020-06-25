//
//  ImagePredictionViewModel.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/22/19.
//

import UIKit

class ChoiceWidgetViewModel {
    var id: String
    var options: [ChoiceWidgetOptionViewModel]
    var question: String
    var timeout: TimeInterval
    var confirmationMessage: String?
    var animationConfirmationAsset: String?
    var animationTimerAsset: String?
    var customData: String?

    init(id: String,
         question: String,
         timeout: TimeInterval,
         options: [ChoiceWidgetOptionViewModel],
         customData: String?) {
        self.id = id
        self.question = question
        self.timeout = timeout
        self.options = options
        self.customData = customData
    }
}

struct ChoiceWidgetOptionViewModel {
    var id: String
    var voteUrl: URL
    var imageUrl: URL?
    var text: String
    var progress: Double?
    var isSelectable: Bool

    init(id: String, voteUrl: URL, image: URL?, text: String, progress: Double?, isSelectable: Bool) {
        self.id = id
        self.voteUrl = voteUrl
        imageUrl = image
        self.text = text
        self.progress = progress
        self.isSelectable = isSelectable
    }
}
