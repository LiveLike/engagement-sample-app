//
//  ImageSliderWidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/2/20.
//

import Foundation

/// Methods for observing changes to a `ImageSliderWidgetModel`
public protocol ImageSliderWidgetModelDelegate: AnyObject {
    /// Called when the server sends updated average magnitude
    func imageSliderWidgetModel(
        _ model: ImageSliderWidgetModel,
        averageMagnitudeDidChange averageMagnitude: Double
    )
}

/// An object that reflects the state of a Image Slider widget on the server
public class ImageSliderWidgetModel: ImageSliderWidgetModelable {

    /// The object that acts as the delegate for the `ImageSliderWidgetModel`
    public weak var delegate: ImageSliderWidgetModelDelegate?

    // MARK: Data

    /// The question posed by the Image Slider widget
    public let question: String
    /// An initial magnitude set by a Producer
    public let initialMagnitude: Double
    /// The latest average magnitude
    @Atomic public internal(set) var averageMagnitude: Double
    /// The options of the Image Slider widget
    public let options: [Option]

    // MARK: Metadata

    public let id: String
    public let kind: WidgetKind
    public let customData: String?
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval

    // MARK: Private Properties

    private let userProfile: UserProfileProtocol
    private let rewardItems: [RewardItem]
    private let leaderboardManager: LeaderboardsManager
    private let voteURL: URL
    private let widgetClient: WidgetClient
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let impressionURL: URL?
    private let subscribeChannel: String

    let eventRecorder: EventRecorder

    init(
        data: ImageSliderCreated,
        eventRecorder: EventRecorder,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        leaderboardManager: LeaderboardsManager,
        livelikeAPI: LiveLikeRestAPIServicable,
        widgetClient: WidgetClient
    ) {

        self.id = data.id
        self.kind = data.kind
        self.question = data.question
        self.voteURL = data.voteUrl
        self.initialMagnitude = Double(data.initialMagnitude) ?? 0
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.interactionTimeInterval = data.timeout.timeInterval
        self.options = data.options.map {
            Option(id: $0.id, imageURL: $0.imageUrl)
        }
        self.averageMagnitude = {
            guard
                let averageMagnitudeString = data.averageMagnitude,
                let averageMagnitude = Double(averageMagnitudeString)
            else {
                return 0.5
            }
            return averageMagnitude
        }()
        self.impressionURL = data.impressionUrl
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardManager = leaderboardManager
        self.livelikeAPI = livelikeAPI
        self.widgetClient = widgetClient
        self.subscribeChannel = data.subscribeChannel

        self.widgetClient.addListener(self, toChannel: self.subscribeChannel)
    }

    deinit {
        self.widgetClient.unsubscribe(fromChannel: subscribeChannel)
    }

    // MARK: Methods

    /// Locks in a vote for the ImageSlider. A user can only have one vote so call this when the user has made their final decision.
    /// Magnitude must by within range [0,1]
    public func lockInVote(magnitude: Double, completion: @escaping (Result<Vote, Error>) -> Void = { _ in }) {
        self.eventRecorder.record(.widgetEngaged(kind: self.kind, id: self.id))
        firstly {
            self.livelikeAPI.createImageSliderVote(
                voteURL: self.voteURL,
                magnitude: magnitude,
                accessToken: userProfile.accessToken
            )
        }.then { vote in
            self.userProfile.notifyRewardItemsEarned(
                rewards: Reward.createRewards(
                    availableRewardItems: self.rewardItems,
                    rewardResources: vote.rewards,
                    widgetInfo: .init(id: self.id, kind: self.kind)
                )
            )
            self.leaderboardManager.notifyCurrentPositionChange(rewards: vote.rewards)
            completion(.success(Vote(id: vote.id)))
        }.catch { error in
            completion(.failure(error))
        }
    }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        self.eventRecorder.record(
            .widgetDisplayed(kind: kind.analyticsName, widgetId: id, widgetLink: nil)
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

    // MARK: Types

    /// An option of the Image Slider
    public struct Option {
        /// The option's id
        public let id: String
        /// The URL of an image representing the Option
        public let imageURL: URL

        init(id: String, imageURL: URL) {
            self.id = id
            self.imageURL = imageURL
        }
    }

    /// An object representing a vote on an Image Slider
    public struct Vote {
        public let id: String
    }
}

///:nodoc:
extension ImageSliderWidgetModel: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case let .imageSliderResults(results):
            guard results.id == self.id else { return }
            guard
                let averageMagnitudeString = results.averageMagnitude,
                let averageMagnitude = Double(averageMagnitudeString)
            else {
                return
            }
            self.averageMagnitude = averageMagnitude
            self.delegate?.imageSliderWidgetModel(self, averageMagnitudeDidChange: averageMagnitude)
        default:
            log.error("Received event \(event.clientEvent.description) in ImageSliderLiveResultsClient when only .imageSliderResults were expected.")
        }
    }

    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
}
