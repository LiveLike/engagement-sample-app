//
//  ImageChoiceWidgetViewModel+Prediction.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/13/19.
//

import UIKit

extension ChoiceWidgetViewModel {
    static func make(from imagePredictionCreated: ImagePredictionCreated) -> ChoiceWidgetViewModel {
        let options: [ChoiceWidgetOptionViewModel] = imagePredictionCreated.options.map { option in
            let optionViewModel = ChoiceWidgetOptionViewModel(id: option.id,
                                                              voteUrl: option.voteUrl,
                                                              image: option.imageUrl,
                                                              text: option.description,
                                                              progress: nil,
                                                              isSelectable: true)
            return optionViewModel
        }
        let imagePredictionViewModel = ChoiceWidgetViewModel(id: imagePredictionCreated.id,
                                                             question: imagePredictionCreated.question,
                                                             timeout: imagePredictionCreated.timeout,
                                                             options: options,
                                                             customData: imagePredictionCreated.customData)
        imagePredictionViewModel.confirmationMessage = imagePredictionCreated.confirmationMessage
        imagePredictionViewModel.animationConfirmationAsset = imagePredictionCreated.animationConfirmationAsset

        return imagePredictionViewModel
    }

    static func make(from imagePredictionFollowUp: ImagePredictionFollowUp, theme: Theme) -> ChoiceWidgetViewModel {
        let totalVotes = Double(imagePredictionFollowUp.options.map { $0.voteCount }.reduce(0, +))
        let options: [ChoiceWidgetOptionViewModel] = imagePredictionFollowUp.options.map { option in
            var percent = 0.0
            if totalVotes > 0 {
                percent = Double(Double(option.voteCount) / totalVotes)
            }

            let optionViewModel = ChoiceWidgetOptionViewModel(id: option.id,
                                                              voteUrl: option.voteUrl,
                                                              image: option.imageUrl,
                                                              text: option.description,
                                                              progress: percent,
                                                              isSelectable: false)
            return optionViewModel
        }

        let imagePredictionViewModel = ChoiceWidgetViewModel(id: imagePredictionFollowUp.id,
                                                             question: imagePredictionFollowUp.question,
                                                             timeout: imagePredictionFollowUp.timeout,
                                                             options: options,
                                                             customData: imagePredictionFollowUp.customData)
        imagePredictionViewModel.animationCorrectAsset = theme.randomCorrectAnimationAsset()
        imagePredictionViewModel.animationIncorrectAsset = theme.randomIncorrectAnimationAsset()

        return imagePredictionViewModel
    }
}
