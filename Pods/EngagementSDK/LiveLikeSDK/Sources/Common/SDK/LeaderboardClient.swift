//
//  LeaderboardClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/15/20.
//

import Foundation

/// Describes a position in a leaderboard
public struct LeaderboardPosition {
    public let rank: Int
    public let score: Int
    public let percentileRank: String

    init(rewardResource: RewardResource) {
        self.rank = rewardResource.newRank
        self.score = rewardResource.newScore
        self.percentileRank = rewardResource.newPercentileRank
    }

    init(rank: Int, score: Int, percentileRank: String) {
        self.rank = rank
        self.score = score
        self.percentileRank = percentileRank
    }
}

/// Methods for managing changes to a Leaderboard
public protocol LeaderboardDelegate: AnyObject {
    /// Tells the delegate that the current user's LeaderboardPlacement has changed
    func leaderboard(_ leaderboardClient: LeaderboardClient, currentPositionDidChange position: LeaderboardPosition)
}

/// Methods for managing a Leaderboard
public class LeaderboardClient {

    public weak var delegate: LeaderboardDelegate?

    /// The id of the Leaderboard
    public let id: String

    /// The name of the Leaderboard
    public let name: String

    /// The Reward Item being tracked by this Leaderboard
    public let rewardItem: RewardItem

    /// The current user's position in this Leaderboard
    /// Their position is `nil` if the user hasn't earned any points on the Leaderboard
    public private(set) var currentPosition: LeaderboardPosition?

    private let leaderboardsManager: LeaderboardsManager

    convenience init(
        leaderboardResource: LeaderboardResource,
        currentLeaderboardEntry: LeaderboardEntryResource?,
        leaderboardsManager: LeaderboardsManager
    ) {
        self.init(
            id: leaderboardResource.id,
            name: leaderboardResource.name,
            rewardItem: RewardItem(
                id: leaderboardResource.rewardItem.id,
                name: leaderboardResource.rewardItem.name
            ),
            currentPosition: {
                guard let leaderboardEntry = currentLeaderboardEntry else {
                    return nil
                }
                return LeaderboardPosition(
                    rank: leaderboardEntry.rank,
                    score: Int(leaderboardEntry.score),
                    percentileRank: leaderboardEntry.percentileRank
                )
            }(),
            leaderboardsManager: leaderboardsManager
        )
    }

    init(
        id: String,
        name: String,
        rewardItem: RewardItem,
        currentPosition: LeaderboardPosition?,
        leaderboardsManager: LeaderboardsManager
    ) {
        self.id = id
        self.name = name
        self.rewardItem = rewardItem
        self.currentPosition = currentPosition
        self.leaderboardsManager = leaderboardsManager
        leaderboardsManager.listeners.addListener(self)
    }
}

extension LeaderboardClient: LeaderboardsManagerDelegate {
    func leaderboardsManager(
        _ leaderboardsManager: LeaderboardsManager,
        currentPositionDidChange position: LeaderboardPosition,
        leaderboardID: String
    ) {
        guard id == leaderboardID else { return }
        self.currentPosition = position
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.leaderboard(self, currentPositionDidChange: position)
        }
    }
}

protocol LeaderboardsManagerDelegate: AnyObject {
    func leaderboardsManager(_ leaderboardsManager: LeaderboardsManager, currentPositionDidChange placement: LeaderboardPosition, leaderboardID: String)
}

class LeaderboardsManager {
    let listeners: Listener<LeaderboardsManagerDelegate> = Listener(dispatchQueueLabel: "com.LiveLike.LeaderboardsManager")

    func notifyCurrentPositionChange(rewards: [RewardResource]){
        rewards.forEach { reward in
            listeners.publish {
                $0.leaderboardsManager(
                    self,
                    currentPositionDidChange: LeaderboardPosition(rewardResource: reward),
                    leaderboardID: reward.leaderboardId
                )
            }
        }
    }
}
