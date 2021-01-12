//
//  WidgetResource.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 10/27/20.
//

import Foundation

enum WidgetResource: CustomStringConvertible, Decodable {

    enum CodingKeys: CodingKey {
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(WidgetKind.self, forKey: .kind)
        switch kind {
        case .textPrediction:
            self = try .textPredictionCreated(TextPredictionCreated(from: decoder))
        case .textPredictionFollowUp:
            self = try .textPredictionFollowUp(TextPredictionFollowUp(from: decoder))
        case .imagePrediction:
            self = try .imagePredictionCreated(ImagePredictionCreated(from: decoder))
        case .imagePredictionFollowUp:
            self = try .imagePredictionFollowUp(ImagePredictionFollowUp(from: decoder))
        case .imagePoll:
            self = try .imagePollCreated(ImagePollCreated(from: decoder))
        case .textPoll:
            self = try .textPollCreated(TextPollCreated(from: decoder))
        case .alert:
            self = try .alertCreated(AlertCreated(from: decoder))
        case .textQuiz:
            self = try .textQuizCreated(TextQuizCreated(from: decoder))
        case .imageQuiz:
            self = try .imageQuizCreated(ImageQuizCreated(from: decoder))
        case .imageSlider:
            self = try .imageSliderCreated(ImageSliderCreated(from: decoder))
        case .cheerMeter:
            self = try .cheerMeterCreated(CheerMeterCreated(from: decoder))
        }
    }

    case textPredictionCreated(TextPredictionCreated)
    case textPredictionFollowUp(TextPredictionFollowUp)
    case imagePredictionCreated(ImagePredictionCreated)
    case imagePredictionFollowUp(ImagePredictionFollowUp)
    case imagePollCreated(ImagePollCreated)
    case textPollCreated(TextPollCreated)
    case alertCreated(AlertCreated)
    case textQuizCreated(TextQuizCreated)
    case imageQuizCreated(ImageQuizCreated)
    case imageSliderCreated(ImageSliderCreated)
    case cheerMeterCreated(CheerMeterCreated)

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
        }
    }

    var programID: String {
        switch self {
        case let .textPredictionCreated(payload):
            return payload.programId
        case let .textPredictionFollowUp(payload):
            return payload.programId
        case let .imagePredictionCreated(payload):
            return payload.programId
        case let .imagePredictionFollowUp(payload):
            return payload.programId
        case let .imagePollCreated(payload):
            return payload.programId
        case let .textPollCreated(payload):
            return payload.programId
        case let .alertCreated(payload):
            return payload.programId
        case let .textQuizCreated(payload):
            return payload.programId
        case let .imageQuizCreated(payload):
            return payload.programId
        case let .imageSliderCreated(payload):
            return payload.programId
        case let .cheerMeterCreated(payload):
            return payload.programId
        }
    }

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
        case let .textPollCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case .alertCreated:
            return "Alert Created Widget"
        case let .textQuizCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .imageQuizCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .imageSliderCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        case let .cheerMeterCreated(payload):
            return "\(payload.kind.stringValue) Titled: \(payload.question)"
        }
    }
}
