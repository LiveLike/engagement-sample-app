//
//  EngagementSDKModels.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 8/3/20.
//

import Foundation

// MARK: - Gamification
public struct Leaderboard {
    public let id: String
    public let name: String
    public let rewardItem: LeaderboardReward
}

public struct LeaderboardReward {
    public let id: String
    public let name: String
}

public struct LeaderboardEntry {
    public let percentileRank: String
    public let profileId: String
    public let rank: Int
    public let score: Double
    public let profileNickname: String
}

public struct LeaderboardEntriesResult {
    public let entries: [LeaderboardEntry]
    public let total: Int
    public let hasPrevious: Bool
    public let hasNext: Bool
}

/// The details of a Reward Item than can be earned
public struct RewardItem {
    /// The reward item id
    public let id: String
    /// The reward item name
    public let name: String
}

/// Describes an earned Reward
public struct Reward {
    /// The Reward Item earned
    public let item: RewardItem
    /// How many of the Reward Item was earned
    public let amount: Int
    /// How this reward was earned
    public let rewardAction: RewardAction

    init(item: RewardItem, amount: Int, rewardAction: RewardAction) {
        self.item = item
        self.amount = amount
        self.rewardAction = rewardAction
    }

    static func createRewards(
        availableRewardItems: [RewardItem],
        rewardResources: [RewardResource],
        widgetInfo: RewardAction.WidgetInfo
    ) -> [Reward] {
        return rewardResources.compactMap { rewardResource in
            guard let rewardItem = availableRewardItems.first(where: { $0.id == rewardResource.rewardItemId }) else {
                return nil
            }
            return Reward(
                item: rewardItem,
                amount: rewardResource.rewardItemAmount,
                rewardAction: .init(rewardActionResource: rewardResource.rewardAction, widgetInfo: widgetInfo)
            )
        }
    }
}

/// The source of a Reward
public enum RewardAction {

    /// Information to associate a Reward to a Widget
    public struct WidgetInfo {
        /// The widget id
        public let id: String
        /// The widget kind
        public let kind: WidgetKind
    }

    public typealias PredictionInfo = WidgetInfo
    public typealias QuizInfo = WidgetInfo
    public typealias PollInfo = WidgetInfo

    // The user has voted on a poll
    case pollVoted(PollInfo)

    // The user has answered a quiz
    case quizAnswered(QuizInfo)

    // The user has answered a quiz correctly
    case quizCorrect(QuizInfo)

    // The user has answered a prediction
    case predictionMade(PredictionInfo)

    // The user has answered a prediction correctly
    case predictionCorrect(PredictionInfo)

    // The user has earned rewards from an undefined action
    case undefined

    init(rewardActionResource: RewardActionResource, widgetInfo: WidgetInfo) {
        switch rewardActionResource {
        case .pollVoted:
            self = .pollVoted(widgetInfo)
        case .quizAnswered:
            self = .quizAnswered(widgetInfo)
        case .quizCorrect:
            self = .quizCorrect(widgetInfo)
        case .predictionMade:
            self = .predictionMade(widgetInfo)
        case .predictionCorrect:
            self = .predictionCorrect(widgetInfo)
        case .undefined:
            self = .undefined
        }
    }
}
