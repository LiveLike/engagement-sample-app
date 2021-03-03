//
//  EventName.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-15.
//

import Foundation

/// Enum outlining the valid event names we can receive from
/// the messaging service (e.g. PubNub)
enum EventName: String, Codable {
    // Widget Events
    case textPredictionCreated = "text-prediction-created"
    case textPredictionResults = "text-prediction-results"
    case textPredictionFollowUpCreated = "text-prediction-follow-up-updated"
    case imagePredictionCreated = "image-prediction-created"
    case imagePredictionResults = "image-prediction-results"
    case imagePredictionFollowUpCreated = "image-prediction-follow-up-updated"
    case imagePollCreated = "image-poll-created"
    case imagePollResults = "image-poll-results"
    case textPollCreated = "text-poll-created"
    case textPollResults = "text-poll-results"
    case alertCreated = "alert-created"
    case textQuizCreated = "text-quiz-created"
    case textQuizResults = "text-quiz-results"
    case imageQuizCreated = "image-quiz-created"
    case imageQuizResults = "image-quiz-results"
    case imageSliderCreated = "emoji-slider-created"
    case imageSliderResults = "emoji-slider-results"
    case cheerMeterCreated = "cheer-meter-created"
    case cheerMeterResults = "cheer-meter-results"
    case socialEmbedCreated = "social-embed-created"
}
