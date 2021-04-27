//
//  CheerMeter.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/2/20.
//

import Foundation

/// Methods for observing changes to a `CheerMeterWidgetModel`
public protocol CheerMeterWidgetModelDelegate: AnyObject {
    /// Called when server sends updated vote counts
    func cheerMeterWidgetModel(
        _ model: CheerMeterWidgetModel,
        voteCountDidChange voteCount: Int,
        forOption optionID: String
    )

    /// Called when a vote request completes
    func cheerMeterWidgetModel(
        _ model: CheerMeterWidgetModel,
        voteRequest: CheerMeterWidgetModel.VoteRequest,
        didComplete result: Result<CheerMeterWidgetModel.Vote, Error>
    )
}

/// This model reflects the state of a Cheer Meter widget on the server
public class CheerMeterWidgetModel: CheerMeterWidgetModelable {

    /// The object that acts as the delegate for the `CheerMeterWidgetModel`.
    public weak var delegate: CheerMeterWidgetModelDelegate?

    // MARK: Data
    
    /// The `Option`s of the Cheer Meter
    public let options: [Option]
    /// The title of the Cheer Meter
    public let title: String

    // MARK: Metadata

    /// The id of the Cheer Meter
    public let id: String
    /// The `WidgetKind` of the Cheer Meter
    public let kind: WidgetKind
    /// The time interval assigned by the Producer
    public let interactionTimeInterval: TimeInterval
    public let customData: String?
    /// The date this Cheer Meter was created on the server
    public let createdAt: Date
    /// The date this Cheer Meter was published by a Producer
    public let publishedAt: Date?
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
    private let subscribeChannel: String
    
    private var batchedVoteCounterByID: [String: Int] = [:]
    private var throttleTimer: Timer?
    
    init(
        data: CheerMeterCreated,
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
        self.title = data.question
        self.interactionTimeInterval = data.timeout.timeInterval
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.options = data.options.map {
            Option(
                id: $0.id,
                voteURL: $0.voteUrl,
                description: $0.description,
                imageURL: $0.imageUrl,
                voteCount: $0.voteCount
            )
        }
        self.subscribeChannel = data.subscribeChannel
            
        // Subscribe for cheer meter events
        self.widgetClient.addListener(self, toChannel: data.subscribeChannel)
    }

    deinit {
        self.widgetClient.unsubscribe(fromChannel: subscribeChannel)
        throttleTimer?.invalidate()
        throttleTimer = nil
    }
    
    // MARK: Methods
    
    /// Call this to submit a vote to the Cheer Meter
    /// This vote will not be submitted immediately. The votes are batched for performance and sent in 1 second intervals.
    /// - Parameter optionID: The id of the `Option` to submit a vote
    public func submitVote(optionID: String) {
        batchedVoteCounterByID[optionID] = (batchedVoteCounterByID[optionID] ?? 0) + 1
        self.eventRecorder.record(
            .widgetEngaged(programID: self.programID, kind: self.kind, id: self.id)
        )
        // Create timer on first vote
        if throttleTimer == nil {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.throttleTimer = timer
                
                // Send batched vote requests for all options
                self.batchedVoteCounterByID.forEach { (optionID, voteCount) in
                    guard voteCount > 0 else { return }
                    guard let voteURL = self.options.first(where: { $0.id == optionID })?.voteURL else { return }
                    
                    let voteRequest = VoteRequest(optionID: optionID, voteCount: voteCount)
                    
                    firstly {
                        self.livelikeAPI.createCheerMeterVote(
                            voteCount: voteCount,
                            voteURL: voteURL,
                            accessToken: self.userProfile.accessToken
                        )
                    }.then { vote in
                        // Notify user profile of new rewards
                        self.userProfile.notifyRewardItemsEarned(
                            rewards: Reward.createRewards(
                                availableRewardItems: self.rewardItems,
                                rewardResources: vote.rewards,
                                widgetInfo: .init(id: self.id, kind: self.kind)
                            )
                        )
                        // Notify leaderboards of new entry
                        self.leaderboardManager.notifyCurrentPositionChange(rewards: vote.rewards)
                        
                        // Notify delegate of successful vote request
                        self.delegate?.cheerMeterWidgetModel(
                            self,
                            voteRequest: voteRequest,
                            didComplete: .success(Vote(optionID: vote.optionId, voteCount: vote.voteCount)))
                    }.catch { error in
                        // Notify delegate of failed vote request
                        self.delegate?.cheerMeterWidgetModel(
                            self,
                            voteRequest: voteRequest,
                            didComplete: .failure(error)
                        )
                    }
                }
                
                // Reset batched vote counter
                self.batchedVoteCounterByID.removeAll()
            }
        }
    }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(completion: @escaping ((Result<Void, Error>) -> Void) = { _ in }) {
        self.eventRecorder.record(
            .widgetDisplayed(programID: programID, kind: kind.analyticsName, widgetId: id, widgetLink: nil)
        )
        guard let impressionURL = self.impressionURL else { return }
        firstly {
            self.livelikeAPI.createImpression(
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
    
    public func markAsInteractive() {
        self.eventRecorder.record(
            .widgetBecameInteractive(programID: programID, kind: kind, widgetID: id)
        )
    }

    // MARK: Types

    /// A batched vote request
    public struct VoteRequest {
        /// The id of the option that was voted
        public let optionID: String
        /// The count of votes to submit
        public let voteCount: Int
    }

    /// Represents a batched Cheer Meter vote
    public struct Vote {
        /// The id of the option that was voted
        public let optionID: String
        /// The count of batched votes
        public let voteCount: Int
    }

    /// A Cheer Meter option
    public class Option {
        internal init(id: String, voteURL: URL, description: String, imageURL: URL, voteCount: Int) {
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
        public let imageURL: URL

        /// The updated total number of votes for this option.
        /// This property is Atomic
        @Atomic public internal(set) var voteCount: Int
    }
}

// MARK: WidgetProxyInput

/// :nodoc:
extension CheerMeterWidgetModel: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        guard case let .cheerMeterResults(payload) = event.clientEvent else {
            return
        }
        guard payload.id == self.id else { return }
        payload.options.forEach { option in
            /// Update the option's voteCount then notify delegate
            self.options.first(where: { $0.id == option.id })?.voteCount = option.voteCount
            self.delegate?.cheerMeterWidgetModel(self, voteCountDidChange: option.voteCount, forOption: option.id)
        }
    }

    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}
    func error(_ error: Error) {}
}
