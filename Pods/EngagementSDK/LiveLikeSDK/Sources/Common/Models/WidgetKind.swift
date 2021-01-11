//
//  WidgetKind.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-04.
//

import Foundation

/// An enumeration of the different kinds of widgets.
public enum WidgetKind: Int {
    case textPrediction
    case textPredictionFollowUp
    case imagePrediction
    case imagePredictionFollowUp
    case imagePoll
    case textPoll
    case alert
    case textQuiz
    case imageQuiz
    case imageSlider
    case cheerMeter
}

public extension WidgetKind {
    /**
     A human readable display name for the type of widget.
     */
    var displayName: String {
        return analyticsName
    }
}

/// :nodoc:
extension WidgetKind {
    // The expected values of 'kind' from widget messages sent from PubNub
    var stringValue: String {
        switch self {
        case .textPrediction: return "text-prediction"
        case .textPredictionFollowUp: return "text-prediction-follow-up"
        case .imagePrediction: return "image-prediction"
        case .imagePredictionFollowUp: return "image-prediction-follow-up"
        case .imagePoll: return "image-poll"
        case .textPoll: return "text-poll"
        case .alert: return "alert"
        case .textQuiz: return "text-quiz"
        case .imageQuiz: return "image-quiz"
        case .imageSlider: return "emoji-slider"
        case .cheerMeter: return "cheer-meter"
        }
    }

    var analyticsName: String {
        switch self {
        case .textPrediction:
            return "Text Prediction"
        case .textPredictionFollowUp:
            return "Text Prediction Follow-Up"
        case .imagePrediction:
            return "Image Prediction"
        case .imagePredictionFollowUp:
            return "Image Prediction Follow-Up"
        case .imagePoll:
            return "Image Poll"
        case .textPoll:
            return "Text Poll"
        case .alert:
            return "Alert"
        case .textQuiz:
            return "Text Quiz"
        case .imageQuiz:
            return "Image Quiz"
        case .imageSlider:
            return "Image Slider"
        case .cheerMeter:
            return "Cheer Meter"
        }
    }
}

/// :nodoc:
extension WidgetKind: Codable {
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.singleValueContainer()
        try encoder.encode(stringValue)
    }

    public init(from decoder: Decoder) throws {
        let decoder = try decoder.singleValueContainer()
        let kindString = try decoder.decode(String.self)
        guard let kind = WidgetKind(stringValue: kindString) else {
            let description = "Invalid WidgetKind string"
            throw DecodingError.dataCorruptedError(in: decoder, debugDescription: description)
        }
        self = kind
    }
}

extension WidgetKind {
    init?(stringValue: String) {
        guard let kind = WidgetKind.allCases.first(where: { $0.stringValue == stringValue }) else {
            return nil
        }
        self = kind
    }
}

extension WidgetKind: CaseIterable {}

extension WidgetKind: Equatable {}
