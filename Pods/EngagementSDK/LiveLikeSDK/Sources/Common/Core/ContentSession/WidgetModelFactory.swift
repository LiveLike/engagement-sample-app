//
//  WidgetModelFactory.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 10/26/20.
//

import Foundation

class WidgetModelFactory {
    private let eventRecorder: EventRecorder
    private let userProfile: UserProfile
    private let leaderboardsManager: LeaderboardsManager
    private let accessToken: AccessToken
    private let widgetClient: WidgetClient
    private let livelikeRestAPIService: LiveLikeRestAPIServicable
    private let rewardItems: [RewardItem]
    private let predictionVoteRepo: PredictionVoteRepository

    init(
        eventRecorder: EventRecorder,
        userProfile: UserProfile,
        rewardItems: [RewardItem],
        leaderboardsManager: LeaderboardsManager,
        accessToken: AccessToken,
        widgetClient: WidgetClient,
        livelikeRestAPIService: LiveLikeRestAPIServicable,
        predictionVoteRepo: PredictionVoteRepository
    ) {
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardsManager = leaderboardsManager
        self.accessToken = accessToken
        self.widgetClient = widgetClient
        self.livelikeRestAPIService = livelikeRestAPIService
        self.predictionVoteRepo = predictionVoteRepo
    }

    func make(from widgetResource: WidgetResource) throws -> WidgetModel {
        switch widgetResource {
        case .cheerMeterCreated(let payload):
            let cheerMeterModel = CheerMeterWidgetModel(
                data: payload,
                userProfile: userProfile,
                rewardItems: rewardItems,
                leaderboardManager: leaderboardsManager,
                livelikeAPI: livelikeRestAPIService,
                widgetClient: widgetClient,
                eventRecorder: eventRecorder
            )
            return .cheerMeter(cheerMeterModel)
        case .alertCreated(let payload):
            let alertModel = AlertWidgetModel(
                data: payload,
                eventRecorder: self.eventRecorder,
                livelikeAPI: self.livelikeRestAPIService,
                userProfile: self.userProfile
            )
            return .alert(alertModel)
        case .textQuizCreated(let payload):
            let model = QuizWidgetModel(
                data: payload,
                eventRecorder: self.eventRecorder,
                userProfile: self.userProfile,
                rewardItems: rewardItems,
                leaderboardsManager: self.leaderboardsManager,
                widgetClient: self.widgetClient,
                livelikeAPI: self.livelikeRestAPIService
            )
            return .quiz(model)
        case .imageQuizCreated(let payload):
            let model = QuizWidgetModel(
                data: payload,
                eventRecorder: self.eventRecorder,
                userProfile: self.userProfile,
                rewardItems: rewardItems,
                leaderboardsManager: self.leaderboardsManager,
                widgetClient: self.widgetClient,
                livelikeAPI: self.livelikeRestAPIService
            )
            return .quiz(model)
        case .textPredictionCreated(let payload):
            let model = PredictionWidgetModel(
                resource: payload,
                eventRecorder: self.eventRecorder,
                userProfile: self.userProfile,
                rewardItems: self.rewardItems,
                voteRepo: self.predictionVoteRepo,
                leaderboardManager: self.leaderboardsManager,
                livelikeAPI: self.livelikeRestAPIService,
                widgetClient: self.widgetClient
            )
            return .prediction(model)
        case .imagePredictionCreated(let payload):
            let model = PredictionWidgetModel(
                resource: payload,
                eventRecorder: self.eventRecorder,
                userProfile: self.userProfile,
                rewardItems: self.rewardItems,
                voteRepo: self.predictionVoteRepo,
                leaderboardManager: self.leaderboardsManager,
                livelikeAPI: self.livelikeRestAPIService,
                widgetClient: self.widgetClient
            )
            return .prediction(model)
        case .textPredictionFollowUp(let payload):
            let model = PredictionFollowUpWidgetModel(
                resource: payload,
                eventRecorder: self.eventRecorder,
                livelikeAPI: self.livelikeRestAPIService,
                rewardItems: self.rewardItems,
                leaderboardsManager: self.leaderboardsManager,
                userProfile: self.userProfile,
                voteRepo: self.predictionVoteRepo
            )
            return .predictionFollowUp(model)
        case .imagePredictionFollowUp(let payload):
            let model = PredictionFollowUpWidgetModel(
                resource: payload,
                eventRecorder: self.eventRecorder,
                livelikeAPI: self.livelikeRestAPIService,
                rewardItems: self.rewardItems,
                leaderboardsManager: self.leaderboardsManager,
                userProfile: self.userProfile,
                voteRepo: self.predictionVoteRepo
            )
            return .predictionFollowUp(model)
        case .textPollCreated(let payload):
            let model = PollWidgetModel(
                data: payload,
                userProfile: self.userProfile,
                rewardItems: self.rewardItems,
                leaderboardManager: self.leaderboardsManager,
                livelikeAPI: self.livelikeRestAPIService,
                widgetClient: self.widgetClient,
                eventRecorder: self.eventRecorder)
            return .poll(model)
        case .imagePollCreated(let payload):
            let model = PollWidgetModel(
                data: payload,
                userProfile: self.userProfile,
                rewardItems: self.rewardItems,
                leaderboardManager: self.leaderboardsManager,
                livelikeAPI: self.livelikeRestAPIService,
                widgetClient: self.widgetClient,
                eventRecorder: self.eventRecorder)
            return .poll(model)

        case .imageSliderCreated(let payload):
            let model = ImageSliderWidgetModel(
                data: payload,
                eventRecorder: self.eventRecorder,
                userProfile: self.userProfile,
                rewardItems: self.rewardItems,
                leaderboardManager: self.leaderboardsManager,
                livelikeAPI: self.livelikeRestAPIService,
                widgetClient: self.widgetClient
            )
            return .imageSlider(model)
        case .socialEmbed(let payload):
            let model = SocialEmbedWidgetModel(
                resource: payload,
                eventRecorder: self.eventRecorder,
                livelikeAPI: self.livelikeRestAPIService,
                userProfile: self.userProfile
            )
            return .socialEmbed(model)
        }
    }

    func make(from widgetResources: [WidgetResource]) -> [WidgetModel] {
        return widgetResources.compactMap { try? self.make(from: $0 ) }
    }

    enum Errors: LocalizedError {
        case unsupportedWidget

        var errorDescription: String? {
            switch self {
            case .unsupportedWidget:
                return "Failed to create a widget model because the widget kind is not supported"
            }
        }
    }

}
