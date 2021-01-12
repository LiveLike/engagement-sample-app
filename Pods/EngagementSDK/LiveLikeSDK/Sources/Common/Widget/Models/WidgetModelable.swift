//
//  WidgetViewModelable.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 10/20/20.
//

import Foundation

protocol WidgetModelable {
    var id: String { get }
    var kind: WidgetKind { get }
    
    /// The date and time the widget has been created
    var createdAt: Date { get }
    
    /// The date and time the widget has been published from the Producer Suite
    var publishedAt: Date? { get }
    
    /// The time interval for which the user is able to interact with the widget
    var interactionTimeInterval: TimeInterval { get }
    
    /// Used to pass misc data 
    var customData: String? { get }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    func registerImpression(completion: @escaping (Result<Void, Error>) -> Void)
    
}

protocol AlertWidgetModelable: WidgetModelable {
    
    /// alert widget title
    var title: String? { get }
    
    /// widget link
    var linkURL: URL? { get }
    
    var linkLabel: String? { get }
    
    /// widget content
    var text: String? { get }
    
    /// image url representing an image
    var imageURL: URL? { get }
    
    /// opens the `link` URL if it's available
    func openLinkUrl()
}

protocol CheerMeterWidgetModelable: WidgetModelable {

    var delegate: CheerMeterWidgetModelDelegate? { get set }

    var title: String { get }

    var options: [CheerMeterWidgetModel.Option] { get }

    func submitVote(optionID: String)

}

protocol QuizWidgetModelable: WidgetModelable {

    var delegate: QuizWidgetModelDelegate? { get set }

    var question: String { get }

    var choices: [QuizWidgetModel.Choice] { get }

    var totalAnswerCount: Int { get }

    func lockInAnswer(choiceID: String, completion: @escaping (Result<QuizWidgetModel.Answer, Error>) -> Void)

}

protocol PredictionWidgetModelable: WidgetModelable {
    var delegate: PredictionWidgetModelDelegate? { get set }

    var question: String { get }

    var options: [PredictionWidgetModel.Option] { get }

    var confirmationMessage: String { get }

    var totalVoteCount: Int { get }

    func lockInVote(optionID: String, completion: @escaping (Result<PredictionVote, Error>) -> Void)

}

protocol PredictionFollowUpWidgetModelable: WidgetModelable {

    var question: String { get }

    var options: [PredictionFollowUpWidgetModel.Option] { get }

    func getVote(completion: @escaping (Result<PredictionVote, Error>) -> Void)

    func claimRewards(vote: PredictionVote, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol PollWidgetModelable: WidgetModelable {
    
    var delegate: PollWidgetModelDelegate? { get set }
    
    var question: String { get }
    
    var options: [PollWidgetModel.Option] { get }

    var totalVoteCount: Int { get }
    
    func submitVote(optionID: String, completion: @escaping (Result<PollWidgetModel.Vote, Error>) -> Void)
        
}

protocol ImageSliderWidgetModelable: WidgetModelable {

    var delegate: ImageSliderWidgetModelDelegate? { get set }

    var question: String { get }

    var initialMagnitude: Double { get }

    var averageMagnitude: Double { get }

    var options: [ImageSliderWidgetModel.Option] { get }

    func lockInVote(magnitude: Double, completion: @escaping (Result<ImageSliderWidgetModel.Vote, Error>) -> Void)
}
