//
//  ClientMessage.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-24.
//

import Foundation

enum ClientEvent: CustomStringConvertible {
    case textPredictionCreated(TextPredictionCreated)
    case textPredictionResults(PredictionResults)
    case textPredictionFollowUp(TextPredictionFollowUp)
    case imagePredictionCreated(ImagePredictionCreated)
    case imagePredictionResults(PredictionResults)
    case imagePredictionFollowUp(ImagePredictionFollowUp)
    case imagePollCreated(ImagePollCreated)
    case imagePollResults(PollResults)
    case textPollCreated(TextPollCreated)
    case alertCreated(AlertCreated)
    case textQuizCreated(TextQuizCreated)
    case textQuizResults(QuizResults)
    case imageQuizCreated(ImageQuizCreated)
    case imageQuizResults(QuizResults)
    case imageSliderCreated(ImageSliderCreated)
    case imageSliderResults(ImageSliderResults)
    case cheerMeterCreated(CheerMeterCreated)
    case cheerMeterResults(CheerMeterResults)
    
    case pointsTutorial(AwardsViewModel)
    case badgeCollect(AwardsViewModel)

    var minimumScheduledTime: EpochTime? {
        switch self {
        case let .textPredictionCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .textPredictionFollowUp(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .imagePredictionCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .imagePredictionFollowUp(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .imagePollCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case .imagePollResults:
            return nil
        case let .textPollCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .alertCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .textQuizCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .imageQuizCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .imageSliderCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case let .cheerMeterCreated(payload):
            return payload.programDateTime?.timeIntervalSince1970.rounded()
        case .textQuizResults,
             .imageQuizResults,
             .imageSliderResults,
             .cheerMeterResults,
             .textPredictionResults,
             .imagePredictionResults:
            return nil
        case .pointsTutorial, .badgeCollect:
            return nil
        }
    }

    var description: String {
        switch self {
        case let .textPredictionCreated(payload):
            return ("\(payload.kind.stringValue) Titled: \(payload.question)")
        case let .textPredictionFollowUp(payload):
            return ("\(payload.kind.stringValue) Titled: \(payload.question)")
        case let .imagePredictionCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .imagePredictionFollowUp(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .imagePollCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .imagePollResults:
            return "Image Poll Results"
        case let .textPollCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .alertCreated:
            return "Alert Created Widget"
        case let .textQuizCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .imageQuizCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .textQuizResults:
            return "Text Quiz Results"
        case .imageQuizResults:
            return "Image Quiz Results"
        case let .imageSliderCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .imageSliderResults:
            return "Image Slider Results"
        case let .cheerMeterCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .cheerMeterResults:
            return "Cheer Meter Results"
        case .pointsTutorial:
            return "Points Tutorial"
        case .badgeCollect:
            return "Badge Collect"
        case .textPredictionResults:
            return "Text Prediction Results"
        case .imagePredictionResults:
            return "Image Prediction Results"
        }
    }

    var kind: String {
        switch self {
        case let .textPredictionCreated(payload):
            return payload.kind.stringValue
        case let .textPredictionFollowUp(payload):
            return payload.kind.stringValue
        case let .imagePredictionCreated(payload):
            return payload.kind.stringValue
        case let .imagePredictionFollowUp(payload):
            return payload.kind.stringValue
        case let .imagePollCreated(payload):
            return payload.kind.stringValue
        case let .textPollCreated(payload):
            return payload.kind.stringValue
        case let .alertCreated(payload):
            return payload.kind.stringValue
        case let .textQuizCreated(payload):
            return payload.kind.stringValue
        case let .imageQuizCreated(payload):
            return payload.kind.stringValue
        case let .imageSliderCreated(payload):
            return payload.kind.stringValue
        case let .cheerMeterCreated(payload):
            return payload.kind.stringValue
        case .textQuizResults,
             .imageQuizResults,
             .imageSliderResults,
             .imagePollResults,
             .cheerMeterResults,
             .pointsTutorial,
             .badgeCollect,
             .textPredictionResults,
             .imagePredictionResults:
            return "undefined"
        }
    }
}
