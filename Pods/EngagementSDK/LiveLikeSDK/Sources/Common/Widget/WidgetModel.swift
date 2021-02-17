//
//  WidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 10/19/20.
//

import Foundation

/// An enum of Widget types and their associated Widget Model object
public enum WidgetModel {
    case cheerMeter(CheerMeterWidgetModel)
    case alert(AlertWidgetModel)
    case quiz(QuizWidgetModel)
    case prediction(PredictionWidgetModel)
    case predictionFollowUp(PredictionFollowUpWidgetModel)
    case poll(PollWidgetModel)
    case imageSlider(ImageSliderWidgetModel)

    public var id: String {
        switch self {
        case .cheerMeter(let model):
            return model.id
        case .alert(let model):
            return model.id
        case .quiz(let model):
            return model.id
        case .prediction(let model):
            return model.id
        case .predictionFollowUp(let model):
            return model.id
        case .poll(let model):
            return model.id
        case .imageSlider(let model):
            return model.id
        }
    }
}
