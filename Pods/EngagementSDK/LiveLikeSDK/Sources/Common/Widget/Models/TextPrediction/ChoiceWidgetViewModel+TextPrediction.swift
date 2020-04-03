//
//  TextChoiceWidgetViewModel+Prediction.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/13/19.
//

import UIKit

extension ChoiceWidgetViewModel {
    static func make(from textPredictionFollowUp: TextPredictionFollowUp, theme: Theme) -> ChoiceWidgetViewModel {
        let totalVotes = Double(textPredictionFollowUp.options.map { $0.voteCount }.reduce(0, +))
        let followUpOptions = textPredictionFollowUp.options.map { option -> ChoiceWidgetOptionViewModel in
            var percent = 0.0
            if totalVotes > 0 {
                percent = Double(Double(option.voteCount) / totalVotes)
            }

            let optionViewModel = ChoiceWidgetOptionViewModel(id: option.id,
                                                              voteUrl: option.voteUrl,
                                                              image: nil,
                                                              text: option.description,
                                                              progress: percent,
                                                              isSelectable: true)

            return optionViewModel
        }

        let viewModel = ChoiceWidgetViewModel(id: textPredictionFollowUp.id, question: textPredictionFollowUp.question, timeout: textPredictionFollowUp.timeout, options: followUpOptions)
        viewModel.animationCorrectAsset = theme.randomCorrectAnimationAsset()
        viewModel.animationIncorrectAsset = theme.randomIncorrectAnimationAsset()
        return viewModel
    }

    static func make(from textPredictionCreated: TextPredictionCreated) -> ChoiceWidgetViewModel {
        let followUpOptions = textPredictionCreated.options.map { option -> ChoiceWidgetOptionViewModel in
            let optionViewModel = ChoiceWidgetOptionViewModel(id: option.id,
                                                              voteUrl: option.voteUrl,
                                                              image: nil,
                                                              text: option.description,
                                                              progress: nil,
                                                              isSelectable: true)
            return optionViewModel
        }
        let viewModel = ChoiceWidgetViewModel(id: textPredictionCreated.id, question: textPredictionCreated.question, timeout: textPredictionCreated.timeout, options: followUpOptions)
        viewModel.animationTimerAsset = textPredictionCreated.animationTimerAsset
        viewModel.animationConfirmationAsset = textPredictionCreated.animationConfirmationAsset
        viewModel.confirmationMessage = textPredictionCreated.confirmationMessage
        return viewModel
    }
}
