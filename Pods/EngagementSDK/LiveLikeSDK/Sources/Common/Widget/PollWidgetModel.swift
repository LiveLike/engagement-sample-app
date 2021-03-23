//
//  PollWidgetModel.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 11/23/20.
//

import Foundation

/// Methods for observing changes to a `PollWidgetModel`
public protocol PollWidgetModelDelegate: AnyObject {
    /// Called when the server sends updated vote counts
    func pollWidgetModel(
        _ model: PollWidgetModel,
        voteCountDidChange voteCount: Int,
        forOption optionID: String
    )
}

/// An object that represents the Poll widget on the server.
public class PollWidgetModel: PollWidgetModelable {
    
    /// The object that acts as the delegate for the `PollWidgetModel`.
    public weak var delegate: PollWidgetModelDelegate?
    
    // MARK: Data
    
    /// The `Option`s of the Poll Widget
    public let options: [Option]
    
    /// The question of the Poll Widget
    public let question: String

    /// The updated total count of votes on the Poll
    @Atomic public internal(set) var totalVoteCount: Int
    
    // MARK: Metadata
    
    public let id: String
    public let kind: WidgetKind
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval
    public let customData: String?
    public let containsImages: Bool
    public let programID: String
    
    // MARK: Internal Properties

    let eventRecorder: EventRecorder
    
    // MARK: Private Properties

    private let userProfile: UserProfileProtocol
    private let rewardItems: [RewardItem]
    private let leaderboardManager: LeaderboardsManager
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let widgetClient: WidgetClient
    private let impressionURL: URL?
    private var lastSuccessfulVote: PollVoteResource?
    private var isVotingInProgress: Bool = false
    private let subscribeChannel: String
    
    init(
        data: TextPollCreated,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        leaderboardManager: LeaderboardsManager,
        livelikeAPI: LiveLikeRestAPIServicable,
        widgetClient: WidgetClient,
        eventRecorder: EventRecorder
    ) {
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardManager = leaderboardManager
        self.livelikeAPI = livelikeAPI
        self.widgetClient = widgetClient
        self.eventRecorder = eventRecorder
        self.impressionURL = data.impressionUrl
        
        self.id = data.id
        self.kind = data.kind
        self.programID = data.programId
        self.question = data.question
        self.options = data.options.map {
            Option(
                id: $0.id,
                voteURL: $0.voteUrl,
                description: $0.description,
                imageURL: nil,
                voteCount: $0.voteCount
            )
        }
        self.totalVoteCount = data.options.map { $0.voteCount }.reduce(0, +)
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.containsImages = false
        self.interactionTimeInterval = data.timeout.timeInterval
        self.subscribeChannel = data.subscribeChannel
        
        self.widgetClient.addListener(self, toChannel: data.subscribeChannel)
    }
    
    init(
        data: ImagePollCreated,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        leaderboardManager: LeaderboardsManager,
        livelikeAPI: LiveLikeRestAPIServicable,
        widgetClient: WidgetClient,
        eventRecorder: EventRecorder
    ) {
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardManager = leaderboardManager
        self.livelikeAPI = livelikeAPI
        self.widgetClient = widgetClient
        self.eventRecorder = eventRecorder
        self.impressionURL = data.impressionUrl
        
        self.id = data.id
        self.kind = data.kind
        self.programID = data.programId
        self.question = data.question
        self.options = data.options.map {
            Option(
                id: $0.id,
                voteURL: $0.voteUrl,
                description: $0.description,
                imageURL: $0.imageUrl,
                voteCount: $0.voteCount
            )
        }
        self.totalVoteCount = data.options.map { $0.voteCount }.reduce(0, +)
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.containsImages = true
        self.interactionTimeInterval = data.timeout.timeInterval
        self.subscribeChannel = data.subscribeChannel
        
        self.widgetClient.addListener(self, toChannel: data.subscribeChannel)
    }

    deinit {
        self.widgetClient.unsubscribe(fromChannel: subscribeChannel)
    }

    // MARK: Methods
    
    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        self.eventRecorder.record(
            .widgetDisplayed(programID: programID, kind: kind.analyticsName, widgetId: id, widgetLink: nil)
        )
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
    
    /// Submit or update an already submitted vote by `optionID`
    public func submitVote(optionID: String, completion: @escaping (Result<PollWidgetModel.Vote, Error>) -> Void = { _ in }){
        self.eventRecorder.record(
            .widgetEngaged(programID: self.programID, kind: self.kind, id: self.id)
        )

        // Avoid repeat vote on a previously voted option
        guard lastSuccessfulVote?.optionId != optionID else {
            log.error("\(PollWidgetModelError.voteAlreadySubmitted.localizedDescription)")
            completion(.failure(PollWidgetModelError.voteAlreadySubmitted))
            return
        }
        
        guard let voteURL = options.first(where: { $0.id == optionID})?.voteURL else {
            log.error("\(PollWidgetModelError.failedDueToInvalidOptionID.localizedDescription)")
            completion(.failure(PollWidgetModelError.failedDueToInvalidOptionID))
            return
        }
        
        let votePromise: Promise<Void>
        self.isVotingInProgress = true
        if lastSuccessfulVote == nil {
            // Create first vote
           votePromise = firstly {
                livelikeAPI.createVoteOnPoll(for: voteURL, accessToken: self.userProfile.accessToken)
            }.then { vote in
                self.lastSuccessfulVote = vote
                
                self.userProfile.notifyRewardItemsEarned(
                    rewards: Reward.createRewards(
                        availableRewardItems: self.rewardItems,
                        rewardResources: vote.rewards,
                        widgetInfo: .init(id: self.id, kind: self.kind)
                    )
                )
                self.leaderboardManager.notifyCurrentPositionChange(rewards: vote.rewards)
                log.debug("Poll vote successfuly created for id \(vote.id)")
                completion(.success(PollWidgetModel.Vote(id: vote.id, optionID: vote.optionId)))
            }.asVoid()
           
        } else {
            
            guard let lastSuccessfulVote = lastSuccessfulVote else {
                log.error("\(PollWidgetModelError.failedUpdatingVote("Cannot update due to missing initial vote"))")
                completion(.failure(PollWidgetModelError.failedUpdatingVote("Cannot update due to missing initial vote")))
                return
            }
            
            // Update vote
            votePromise = firstly {
                livelikeAPI.updateVoteOnPoll(for: optionID, optionURL: lastSuccessfulVote.url, accessToken: self.userProfile.accessToken)
            }.then { vote in
                self.lastSuccessfulVote = vote
                log.debug("Poll vote successfuly updated for id \(vote.id)")
                completion(.success(PollWidgetModel.Vote(id: vote.id, optionID: vote.optionId)))
            }.asVoid()
            
        }
        
        votePromise.catch { error in
            completion(.failure(PollWidgetModelError.failedUpdatingVote(error.localizedDescription)))
            log.error("Failed to submit vote because: \(error.localizedDescription)")
        }.always {
            self.isVotingInProgress = false
        }
    }

    // MARK: Types
    
    // A Poll option
    public class Option {
       
        internal init(
            id: String,
            voteURL: URL,
            description: String,
            imageURL: URL?,
            voteCount: Int
        ) {
            self.id = id
            self.voteURL = voteURL
            self.text = description
            self.imageURL = imageURL
            self.voteCount = voteCount
        }

        /// The id of the option. Use this to submit votes.
        public let id: String

        let voteURL: URL

        /// The option's text.
        public let text: String

        /// The option's image url.
        public let imageURL: URL?

        /// The updated total number of votes for this option.
        /// This property is Atomic
        @Atomic public internal(set) var voteCount: Int
    }
    
    /// An object representing a successfully submitted vote
    public struct Vote {
        /// The vote id
        public let id: String
        /// The option ID the user pressed
        public let optionID: String
    }
}

///:nodoc:
extension PollWidgetModel: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case let .imagePollResults(results):
            guard results.id == self.id else { return }
            // Update model
            self.totalVoteCount = results.options.map { $0.voteCount }.reduce(0, +)
            results.options.forEach { option in
                self.options.first(where: { $0.id == option.id})?.voteCount = option.voteCount
            }
            // Notify delegate
            guard let delegate = self.delegate else { return }
            results.options.forEach { option in
                delegate.pollWidgetModel(
                    self,
                    voteCountDidChange: option.voteCount,
                    forOption: option.id
                )
            }
        default:
            log.error("Failed processing event for PollWidgetModel with error - \(event.clientEvent.description)")
        }
    }
    
    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}
    func error(_ error: Error) { log.error(error.localizedDescription) }
}
