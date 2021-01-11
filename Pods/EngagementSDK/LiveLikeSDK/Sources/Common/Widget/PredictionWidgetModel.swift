//
//  PredictionWidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/2/20.
//

import Foundation

/// Methods for observing changes to a `PredictionWidgetModel`
public protocol PredictionWidgetModelDelegate: AnyObject {
    /// Called when the server sends updated vote counts
    func predictionWidgetModel(
        _ model: PredictionWidgetModel,
        voteCountDidChange voteCount: Int,
        forOption optionID: String
    )
}

/// An object that reflects the state of a Prediction widget on the server
public class PredictionWidgetModel: PredictionWidgetModelable {

    /// The object that acts as the delegate for the `PredictionWidgetModel`
    public weak var delegate: PredictionWidgetModelDelegate?

    // MARK: Data

    /// The question of the Prediction
    public let question: String
    /// The options of the Predictions
    public let options: [Option]
    /// A message to show the user when their prediction is locked in
    public let confirmationMessage: String
    /// Does the Prediction widget contain images
    public let containsImages: Bool
    /// The updated total count of votes on the Prediction
    @Atomic public internal(set) var totalVoteCount: Int

    // MARK: Metadata

    public let id: String
    public let kind: WidgetKind
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval
    public let customData: String?

    // MARK: Internal Properties

    let eventRecorder: EventRecorder

    // MARK: Private Properties

    private let userProfile: UserProfileProtocol
    private let rewardItems: [RewardItem]
    private let voteRepo: PredictionVoteRepository
    private let leaderboardManager: LeaderboardsManager
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let widgetClient: WidgetClient
    private let impressionURL: URL?
    private let subscribeChannel: String

    init(
        resource: TextPredictionCreated,
        eventRecorder: EventRecorder,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        voteRepo: PredictionVoteRepository,
        leaderboardManager: LeaderboardsManager,
        livelikeAPI: LiveLikeRestAPIServicable,
        widgetClient: WidgetClient
    ) {
        self.question = resource.question
        self.options = resource.options.map { Option(resource: $0) }
        self.confirmationMessage = resource.confirmationMessage
        self.containsImages = false
        self.totalVoteCount = resource.options.map { $0.voteCount }.reduce(0, +)
        self.id = resource.id
        self.kind = resource.kind
        self.createdAt = resource.createdAt
        self.publishedAt = resource.publishedAt
        self.interactionTimeInterval = resource.timeout
        self.customData = resource.customData
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.voteRepo = voteRepo
        self.leaderboardManager = leaderboardManager
        self.livelikeAPI = livelikeAPI
        self.widgetClient = widgetClient
        self.impressionURL = resource.impressionUrl
        self.subscribeChannel = resource.subscribeChannel

        self.widgetClient.addListener(self, toChannel: resource.subscribeChannel)
    }

    init(
        resource: ImagePredictionCreated,
        eventRecorder: EventRecorder,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        voteRepo: PredictionVoteRepository,
        leaderboardManager: LeaderboardsManager,
        livelikeAPI: LiveLikeRestAPIServicable,
        widgetClient: WidgetClient
    ) {
        self.question = resource.question
        self.options = resource.options.map { Option(resource: $0) }
        self.confirmationMessage = resource.confirmationMessage
        self.containsImages = true
        self.totalVoteCount = resource.options.map { $0.voteCount }.reduce(0, +)
        self.id = resource.id
        self.kind = resource.kind
        self.createdAt = resource.createdAt
        self.publishedAt = resource.publishedAt
        self.interactionTimeInterval = resource.timeout
        self.customData = resource.customData
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.voteRepo = voteRepo
        self.leaderboardManager = leaderboardManager
        self.livelikeAPI = livelikeAPI
        self.widgetClient = widgetClient
        self.impressionURL = resource.impressionUrl
        self.subscribeChannel = resource.subscribeChannel

        self.widgetClient.addListener(self, toChannel: resource.subscribeChannel)
    }

    deinit {
        self.widgetClient.unsubscribe(fromChannel: subscribeChannel)
    }

    // MARK: Methods

    /// Locks in a vote for the Prediction. Call this when the user has made their final decision. Only one vote is allowed per user.
    public func lockInVote(optionID: String, completion: @escaping ((Result<PredictionVote, Error>) -> Void) = { _ in }) {
        guard let voteURL = self.options.first(where: { $0.id == optionID })?.voteURL else { return }

        // Send vote
        firstly {
            self.livelikeAPI.createPredictionVote(voteURL: voteURL, accessToken: self.userProfile.accessToken)
        }.then { [weak self] vote in
            guard let self = self else { return }
            let predictionVote = PredictionVote(
                id: vote.id,
                widgetID: self.id,
                optionID: vote.optionId,
                claimToken: vote.claimToken
            )
            self.voteRepo.add(
                vote: predictionVote,
                completion: { _ in }
            )
            self.userProfile.notifyRewardItemsEarned(
                rewards: Reward.createRewards(
                    availableRewardItems: self.rewardItems,
                    rewardResources: vote.rewards,
                    widgetInfo: .init(id: self.id, kind: self.kind)
                )
            )
            self.leaderboardManager.notifyCurrentPositionChange(rewards: vote.rewards)
            completion(.success(predictionVote))
        }.catch { error in
            completion(.failure(error))
        }
    }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let impressionURL = self.impressionURL else { return }
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

    /// A Prediction Option
    public class Option {
        /// The id of the Option. Use this to `lockInVote`.
        public let id: String
        /// The text description of the Option
        public let text: String
        /// The image of the Option
        public let imageURL: URL?
        /// The update total vote count for the Option
        @Atomic public internal(set) var voteCount: Int

        let voteURL: URL

        init(resource: TextPredictionCreatedOption) {
            self.id = resource.id
            self.text = resource.description
            self.imageURL = nil
            self.voteCount = resource.voteCount
            self.voteURL = resource.voteUrl
        }

        init(resource: ImagePredictionOption) {
            self.id = resource.id
            self.text = resource.description
            self.imageURL = resource.imageUrl
            self.voteCount = resource.voteCount
            self.voteURL = resource.voteUrl
        }
    }
}

// MARK: WidgetProxyInput

///:nodoc:
extension PredictionWidgetModel: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case .textPredictionResults(let results), .imagePredictionResults(let results):
            // Update model
            self.totalVoteCount = results.options.map { $0.voteCount }.reduce(0, +)
            results.options.forEach { result in
                self.options.first(where: { $0.id == result.id })?.voteCount = result.voteCount
            }
            // Notify delegate
            results.options.forEach { result in
                self.delegate?.predictionWidgetModel(self, voteCountDidChange: result.voteCount, forOption: result.id)
            }
        default:
            log.error("Unexpected message payload on this channel.")
        }
    }

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }

    // Not implemented
    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}
}
