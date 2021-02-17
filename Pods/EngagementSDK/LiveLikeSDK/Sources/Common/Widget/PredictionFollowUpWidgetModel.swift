//
//  PredictionFollowUpWidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/19/20.
//

import Foundation

/// An object that reflects the state of a Prediction Follow Up widget on the server
public class PredictionFollowUpWidgetModel: PredictionFollowUpWidgetModelable {

    // MARK: Data

    /// The question of the Prediction Follow Up
    public let question: String
    /// The options of the Prediction Follow Up
    public let options: [Option]
    /// Does the Prediction Follow Up widget contain images
    public let containsImages: Bool

    // MARK: Metadata

    public let id: String
    public let kind: WidgetKind
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval
    public let customData: String?
    /// The id of the associated Prediction widget
    public let associatedPredictionID: String
    /// The kind of the associated Prediction widget
    public let associatedPredictionKind: WidgetKind

    // MARK: Internal Properties

    let eventRecorder: EventRecorder

    // MARK: Private Properties

    private let userProfile: UserProfile
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let rewardItems: [RewardItem]
    private let leaderboardsManager: LeaderboardsManager
    private let impressionURL: URL?
    private let claimURL: URL
    private let voteRepo: PredictionVoteRepository
    private var isGetVoteInProgress: Bool = false

    init(
        resource: TextPredictionFollowUp,
        eventRecorder: EventRecorder,
        livelikeAPI: LiveLikeRestAPIServicable,
        rewardItems: [RewardItem],
        leaderboardsManager: LeaderboardsManager,
        userProfile: UserProfile,
        voteRepo: PredictionVoteRepository
    ) {
        self.question = resource.question
        self.options = resource.options.map { Option(resource: $0) }
        self.containsImages = false
        self.id = resource.id
        self.kind = resource.kind
        self.createdAt = resource.createdAt
        self.publishedAt = resource.publishedAt
        self.interactionTimeInterval = resource.timeout
        self.customData = resource.customData
        self.impressionURL = resource.impressionUrl
        self.claimURL = resource.claimUrl
        self.eventRecorder = eventRecorder
        self.livelikeAPI = livelikeAPI
        self.rewardItems = rewardItems
        self.leaderboardsManager = leaderboardsManager
        self.userProfile = userProfile
        self.associatedPredictionID = resource.textPredictionId
        self.associatedPredictionKind = .textPrediction
        self.voteRepo = voteRepo
    }

    init(
        resource: ImagePredictionFollowUp,
        eventRecorder: EventRecorder,
        livelikeAPI: LiveLikeRestAPIServicable,
        rewardItems: [RewardItem],
        leaderboardsManager: LeaderboardsManager,
        userProfile: UserProfile,
        voteRepo: PredictionVoteRepository
    ) {
        self.question = resource.question
        self.options = resource.options.map { Option(resource: $0) }
        self.containsImages = true
        self.id = resource.id
        self.kind = resource.kind
        self.createdAt = resource.createdAt
        self.publishedAt = resource.publishedAt
        self.interactionTimeInterval = resource.timeout
        self.customData = resource.customData
        self.impressionURL = resource.impressionUrl
        self.claimURL = resource.claimUrl
        self.eventRecorder = eventRecorder
        self.livelikeAPI = livelikeAPI
        self.rewardItems = rewardItems
        self.leaderboardsManager = leaderboardsManager
        self.userProfile = userProfile
        self.associatedPredictionID = resource.imagePredictionId
        self.associatedPredictionKind = .imagePrediction
        self.voteRepo = voteRepo
    }

    // MARK: Methods

    /// Returns the User's `PredictionVote` if any exists.
    public func getVote(completion: @escaping (Result<PredictionVote, Error>) -> Void) {
        guard !isGetVoteInProgress else  {
            completion(.failure(PredictionFollowUpModelErrors.concurrentGetVote))
            return
        }
        self.isGetVoteInProgress = true
        voteRepo.get(by: associatedPredictionID) { [weak self] vote in
            guard let self = self else { return }
            guard let vote = vote else {
                completion(.failure(PredictionFollowUpModelErrors.couldNotFindVote))
                return
            }
            completion(.success(vote))
            self.isGetVoteInProgress = false
        }
    }

    /// Call this method with the user's `PredictionVote` to claim the rewards the user has earned
    public func claimRewards(vote: PredictionVote, completion: @escaping ((Result<Void, Error>) -> Void) = { _ in }) {
        guard let claimToken = vote.claimToken else {
            completion(.failure(PredictionFollowUpModelErrors.claimTokenNotFound))
            return
        }
        firstly {
            self.livelikeAPI.claimRewards(
                claimURL: self.claimURL,
                claimToken: claimToken,
                accessToken: self.userProfile.accessToken
            )
        }.then {
            self.userProfile.notifyRewardItemsEarned(
                rewards: Reward.createRewards(
                    availableRewardItems: self.rewardItems,
                    rewardResources: $0.rewards,
                    widgetInfo: .init(id: self.id, kind: self.kind)
                )
            )
            self.leaderboardsManager.notifyCurrentPositionChange(rewards: $0.rewards)
            completion(.success(()))
        }.catch { error in
            log.error(error)
            completion(.failure(error))
        }
    }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        self.eventRecorder.record(
            .widgetDisplayed(kind: kind.analyticsName, widgetId: id, widgetLink: nil)
        )
        guard let impressionURL = impressionURL else { return }
        firstly {
            livelikeAPI.createImpression(
                impressionURL: impressionURL,
                userSessionID: self.userProfile.userID.asString,
                accessToken: self.userProfile.accessToken
            )
        }.then { _ in
            completion(.success(()))
        }.catch { error in
            completion(.failure(error))
        }
    }

    // MARK: Types

    /// A Prediction Follow Up Option
    public class Option {
        /// The id of the Option
        public let id: String
        /// The text description of the Option
        public let text: String
        /// The text description of the Option
        public let imageURL: URL?
        /// Is this Option correct
        public let isCorrect: Bool
        /// The final vote count of the Option
        public let voteCount: Int

        init(resource: TextPredictionFollowUpOption) {
            self.id = resource.id
            self.text = resource.description
            self.imageURL = nil
            self.isCorrect = resource.isCorrect
            self.voteCount = resource.voteCount
        }

        init(resource: ImagePredictionFollowUpOption) {
            self.id = resource.id
            self.text = resource.description
            self.imageURL = resource.imageUrl
            self.isCorrect = resource.isCorrect
            self.voteCount = resource.voteCount
        }
    }
}
