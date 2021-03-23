//
//  WidgetFactory.swift
//  EngagementSDK
//
//  Created by jelzon on 4/8/19.
//

import Foundation
import UIKit

/// A factory that builds the EngagementSDK's Default Widget UI for each `WidgetModel`
public class DefaultWidgetFactory {
    public static func makeWidget(from widgetModel: WidgetModel) -> Widget? {
        switch widgetModel {
        case .alert(let model):
            return AlertWidgetViewController(model: model)
        case .cheerMeter(let model):
            guard
                let firstOption = model.options[safe: 0],
                let secondOption = model.options[safe: 1]
            else {
                return nil
            }
            return CheerMeterWidgetViewController(
                model: model,
                firstOption: firstOption,
                secondOption: secondOption
            )
        case .quiz(let model):
            return QuizWidgetViewController(model: model)
        case .prediction(let model):
            return PredictionWidgetViewController(model: model)
        case .predictionFollowUp(let model):
            return PredictionFollowUpViewController(model: model)
        case .poll(let model):
            return PollWidgetViewController(model: model)
        case .imageSlider(let model):
            return ImageSliderViewController(model: model)
        case .socialEmbed(let model):
            return SocialEmbedWidgetViewController(model: model)
        }
    }
}
