//
//  WidgetPayloadParser.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/8/20.
//

import Foundation

struct WidgetPayloadParser {
    
    private init() { }
    
    static func parse(_ jsonObject: Any) throws -> ClientEvent {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let widgetKindResource = try JSONDecoder().decode(WidgetKindResource.self, from: jsonData)
        return try parsePayload(for: widgetKindResource.kind, jsonObject: jsonObject)
    }
    
    struct WidgetKindResource: Decodable {
        let kind: WidgetKind
    }
    
    static func parsePayload(for widgetKind: WidgetKind, jsonObject: Any) throws -> ClientEvent {
        let jsonData = try JSONSerialization.data(
            withJSONObject: jsonObject,
            options: .prettyPrinted
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        switch widgetKind {
            
        case .textPrediction:
            let textPrediction = try decoder.decode(TextPredictionCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textPredictionCreated(textPrediction)
            return clientEvent
        case .textPredictionFollowUp:
            let textPredictionFollowUp = try decoder.decode(TextPredictionFollowUp.self, from: jsonData)
            let clientEvent = ClientEvent.textPredictionFollowUp(textPredictionFollowUp)
            return clientEvent
        case .imagePrediction:
            let imagePrediction = try decoder.decode(ImagePredictionCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imagePredictionCreated(imagePrediction)
            return clientEvent
        case .imagePredictionFollowUp:
            let imagePredictionFollowUp = try decoder.decode(ImagePredictionFollowUp.self, from: jsonData)
            let clientEvent = ClientEvent.imagePredictionFollowUp(imagePredictionFollowUp)
            return clientEvent
        case .imagePoll:
            let imagePollCreated = try decoder.decode(ImagePollCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imagePollCreated(imagePollCreated)
            return clientEvent
        case .textPoll:
            let textPollCreated = try decoder.decode(TextPollCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textPollCreated(textPollCreated)
            return clientEvent
        case .alert:
            let alertCreated = try decoder.decode(AlertCreated.self, from: jsonData)
            let clientEvent = ClientEvent.alertCreated(alertCreated)
            return clientEvent
        case .textQuiz:
            let textQuizCreated = try decoder.decode(TextQuizCreated.self, from: jsonData)
            let clientEvent = ClientEvent.textQuizCreated(textQuizCreated)
            return clientEvent
        case .imageQuiz:
            let imageQuizCreated = try decoder.decode(ImageQuizCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imageQuizCreated(imageQuizCreated)
            return clientEvent
        case .imageSlider:
            let imageSliderCreated = try decoder.decode(ImageSliderCreated.self, from: jsonData)
            let clientEvent = ClientEvent.imageSliderCreated(imageSliderCreated)
            return clientEvent
        case .cheerMeter:
            let cheerMeterCreated = try decoder.decode(CheerMeterCreated.self, from: jsonData)
            let clientEvent = ClientEvent.cheerMeterCreated(cheerMeterCreated)
            return clientEvent
        case .gamification:
            throw NilError()
        }
    }

}
