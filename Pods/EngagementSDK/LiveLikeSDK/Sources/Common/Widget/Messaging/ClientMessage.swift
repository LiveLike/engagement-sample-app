//
//  ClientMessage.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-24.
//

import Foundation

enum ClientEvent: CustomStringConvertible, Decodable {
    enum CodingKeys: CodingKey {
        case event
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let event = try container.decode(EventName.self, forKey: .event)

        switch event {
        case .textPredictionCreated,
             .textPredictionFollowUpCreated,
             .imagePredictionCreated,
             .imagePredictionFollowUpCreated,
             .imagePollCreated,
             .textPollCreated,
             .alertCreated,
             .textQuizCreated,
             .imageQuizCreated,
             .imageSliderCreated,
             .cheerMeterCreated:
            self = try .widget(container.decode(WidgetResource.self, forKey: .payload))
        case .textPredictionResults:
            self = try .textPredictionResults(container.decode(PredictionResults.self, forKey: .payload))
        case .imagePredictionResults:
            self = try .imagePredictionResults(container.decode(PredictionResults.self, forKey: .payload))
        case .imagePollResults, .textPollResults:
            self = try .imagePollResults(container.decode(PollResults.self, forKey: .payload))
        case .textQuizResults:
            self = try .textQuizResults(container.decode(QuizResults.self, forKey: .payload))
        case .imageQuizResults:
            self = try .imageQuizResults(container.decode(QuizResults.self, forKey: .payload))
        case .imageSliderResults:
            self = try .imageSliderResults(container.decode(ImageSliderResults.self, forKey: .payload))
        case .cheerMeterResults:
            self = try .cheerMeterResults(container.decode(CheerMeterResults.self, forKey: .payload))
        }
    }

    case widget(WidgetResource)
    case textPredictionResults(PredictionResults)
    case imagePredictionResults(PredictionResults)
    case imagePollResults(PollResults)
    case textQuizResults(QuizResults)
    case imageQuizResults(QuizResults)
    case imageSliderResults(ImageSliderResults)
    case cheerMeterResults(CheerMeterResults)

    var description: String {
        switch self {
        case .widget(let resource):
            return resource.description
        case .imagePollResults:
            return "Image Poll Results"
        case .textQuizResults:
            return "Text Quiz Results"
        case .imageQuizResults:
            return "Image Quiz Results"
        case .imageSliderResults:
            return "Image Slider Results"
        case .cheerMeterResults:
            return "Cheer Meter Results"
        case .textPredictionResults:
            return "Text Prediction Results"
        case .imagePredictionResults:
            return "Image Prediction Results"
        }
    }

    var minimumScheduledTime: EpochTime? {
        switch self {
        case .widget(let resource):
            return resource.minimumScheduledTime
        case .imagePollResults,
             .textQuizResults,
             .imageQuizResults,
             .imageSliderResults,
             .cheerMeterResults,
             .textPredictionResults,
             .imagePredictionResults:
            return nil
        }
    }

}
