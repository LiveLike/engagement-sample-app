//
//  QuizWidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/2/20.
//

import Foundation

/// Methods for observing changes to a `QuizWidgetModel`
public protocol QuizWidgetModelDelegate: AnyObject {
    /// Called when the sends updated vote counts
    func quizWidgetModel(
        _ model: QuizWidgetModel,
        answerCountDidChange answerCount: Int,
        forChoice choiceID: String
    )
}

/// An object that reflects the state of a Quiz widget on the server
public class QuizWidgetModel: QuizWidgetModelable {

    /// The object that acts as the delegate for the `QuizWidgetModel`.
    public weak var delegate: QuizWidgetModelDelegate?

    // MARK: Data

    /// The question of the Quiz
    public let question: String
    /// The choices of the Quiz
    public let choices: [Choice]
    /// Does the Quiz contain images
    public let containsImages: Bool
    /// The updated total count of answers on the Quiz
    @Atomic public internal(set) var totalAnswerCount: Int

    // MARK: Metadata

    public let id: String
    public let kind: WidgetKind
    public let customData: String?
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval

    // MARK: Internal Properties

    let eventRecorder: EventRecorder

    // MARK: Private Properties

    private let widgetClient: WidgetClient
    private let userProfile: UserProfileProtocol
    private let rewardItems: [RewardItem]
    private let leaderboardsManager: LeaderboardsManager
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let impressionURL: URL?
    private var isLockInAnswerInProgress: Bool = false
    private let subscribeChannel: String

    init(
        data: TextQuizCreated,
        eventRecorder: EventRecorder,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        leaderboardsManager: LeaderboardsManager,
        widgetClient: WidgetClient,
        livelikeAPI: LiveLikeRestAPIServicable
    ) {
        self.id = data.id
        self.kind = data.kind
        self.question = data.question
        self.choices = data.choices.map { Choice(data: $0) }
        self.totalAnswerCount = data.choices.map { $0.answerCount }.reduce(0, +)
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.interactionTimeInterval = data.timeout.timeInterval
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardsManager = leaderboardsManager
        self.containsImages = false
        self.widgetClient = widgetClient
        self.livelikeAPI = livelikeAPI
        self.impressionURL = data.impressionUrl
        self.subscribeChannel = data.subscribeChannel

        self.widgetClient.addListener(self, toChannel: subscribeChannel)
    }

    init(
        data: ImageQuizCreated,
        eventRecorder: EventRecorder,
        userProfile: UserProfileProtocol,
        rewardItems: [RewardItem],
        leaderboardsManager: LeaderboardsManager,
        widgetClient: WidgetClient,
        livelikeAPI: LiveLikeRestAPIServicable
    ) {
        self.id = data.id
        self.kind = data.kind
        self.question = data.question
        self.choices = data.choices.map { Choice(data: $0) }
        self.totalAnswerCount = data.choices.map { $0.answerCount }.reduce(0, +)
        self.customData = data.customData
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.interactionTimeInterval = data.timeout.timeInterval
        self.eventRecorder = eventRecorder
        self.userProfile = userProfile
        self.rewardItems = rewardItems
        self.leaderboardsManager = leaderboardsManager
        self.containsImages = true
        self.widgetClient = widgetClient
        self.livelikeAPI = livelikeAPI
        self.impressionURL = data.impressionUrl
        self.subscribeChannel = data.subscribeChannel

        self.widgetClient.addListener(self, toChannel: subscribeChannel)
    }

    deinit {
        self.widgetClient.unsubscribe(fromChannel: subscribeChannel)
    }

    // MARK: Methods

    /// Locks in an answer for the Quiz. Call this when the user has made their final decision. Once an answer is locked it cannot be changed.
    public func lockInAnswer(choiceID: String, completion: @escaping (Result<Answer, Error>) -> Void) {
        guard !isLockInAnswerInProgress else {
            completion(.failure(QuizWidgetModelError.concurrentLockInAnswer))
            return
        }
        guard let answerURL = choices.first(where: { $0.id == choiceID})?.answerURL else {
            completion(.failure(QuizWidgetModelError.invalidChoiceID(choiceID)))
            return
        }

        self.isLockInAnswerInProgress = true
        firstly {
            livelikeAPI.createQuizAnswer(answerURL: answerURL, accessToken: self.userProfile.accessToken)
        }.then { answer in
            self.userProfile.notifyRewardItemsEarned(
                rewards: Reward.createRewards(
                    availableRewardItems: self.rewardItems,
                    rewardResources: answer.rewards,
                    widgetInfo: .init(id: self.id, kind: self.kind)
                )
            )
            self.leaderboardsManager.notifyCurrentPositionChange(rewards: answer.rewards)
            completion(.success(Answer(choiceID: answer.choiceId)))
        }.catch { error in
            completion(.failure(error))
        }.always {
            self.isLockInAnswerInProgress = false
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

    enum QuizWidgetModelError: LocalizedError {
        case concurrentLockInAnswer
        case invalidChoiceID(String)

        var errorDescription: String? {
            switch self {
            case .concurrentLockInAnswer:
                return "Cannot make concurrent calls to `lockInAnswer`. Wait until the `completion` is called before calling again."
            case .invalidChoiceID(let choiceID):
                return "Could not find option with id \(choiceID)"
            }
        }
    }

    /// A Quiz choice
    public class Choice {
        /// The id of the Choice. Use this to `lockInAnswer`.
        public let id: String
        /// The text of the Choice
        public let text: String
        /// Whether or not the Choice is correct
        public let isCorrect: Bool
        /// The image of the Choice
        public let imageURL: URL?
        /// The updated total answer count
        @Atomic public internal(set) var answerCount: Int

        let answerURL: URL

        init(data: TextQuizChoice) {
            self.id = data.id
            self.text = data.description
            self.isCorrect = data.isCorrect
            self.answerURL = data.answerUrl
            self.imageURL = nil
            self.answerCount = data.answerCount
        }

        init(data: ImageQuizChoice) {
            self.id = data.id
            self.text = data.description
            self.isCorrect = data.isCorrect
            self.answerCount = data.answerCount
            self.answerURL = data.answerUrl
            self.imageURL = data.imageUrl
        }
    }

    /// An object representing the user's Answer to a Quiz
    public struct Answer {
        /// The id of the choice of their Answer
        public let choiceID: String
    }
}

// MARK: WidgetProxyInput

///:nodoc:
extension QuizWidgetModel: WidgetProxyInput {
    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case let .textQuizResults(results), let .imageQuizResults(results):
            // Update model
            self.totalAnswerCount = results.choices.map { $0.answerCount }.reduce(0, +)
            results.choices.forEach { choice in
                self.choices.first(where: { $0.id == choice.id})?.answerCount = choice.answerCount
            }
            // Notify delegate
            guard let delegate = self.delegate else { return }
            results.choices.forEach { choice in
                delegate.quizWidgetModel(self, answerCountDidChange: choice.answerCount, forChoice: choice.id)
            }
        default:
            log.error("Received event \(event.clientEvent.description) in QuizWidgetLiveResultsClient when only .textQuizResults were expected.")
        }
    }

    func discard(event: WidgetProxyPublishData, reason: DiscardedReason) {}
    func connectionStatusDidChange(_ status: ConnectionStatus) {}

    func error(_ error: Error) {
        log.error(error.localizedDescription)
    }
}
