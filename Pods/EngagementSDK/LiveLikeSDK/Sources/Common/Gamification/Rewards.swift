//
//  Rewards.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/29/19.
//

import Foundation

protocol RewardsDelegate: AnyObject {
    func rewards(noAwardsForWidget widgetID: String)
    func rewards(didReceiveAwards awards: Awards, awardsProfile: AwardsProfile, widgetID: String)
    func rewards(didRecieveError error: Error)
}

class Rewards {

    private var delegates: Listener<RewardsDelegate> = Listener()
    private let rewardsURLRepo: RewardsURLRepo
    private let rewardsClient: APIRewardsClient
    private let rewardsType: RewardsType

    // Analytics
    private let superPropertyRecorder: SuperPropertyRecorder
    private let peoplePropertyRecorder: PeoplePropertyRecorder

    // The last badge that the user collected
    private var lastCollectedBadge: Badge? {
        didSet{
            currentBadgeDidChange.forEach { $0(lastCollectedBadge) }
        }
    }

    // The last badge the user has earned
    private(set) var lastEarnedBadge: Badge?

    var currentBadge: Badge? {
        return lastCollectedBadge
    }

    private(set) var currentRank: Int? {
        didSet {
            currentRankDidChange.forEach { $0(currentRank) }
        }
    }

    private(set) var currentPoints: Int? {
        didSet {
            currentPointsDidChange.forEach { $0(currentPoints) }
        }
    }

    var currentBadgeDidChange: [(Badge?) -> Void] = []
    var currentRankDidChange: [(Int?) -> Void] = []
    var currentPointsDidChange: [(Int?) -> Void] = []

    init(rewardsURLRepo: RewardsURLRepo,
         rewardsClient: APIRewardsClient,
         rewardsType: RewardsType,
         superPropertyRecorder: SuperPropertyRecorder,
         peoplePropertyRecorder: PeoplePropertyRecorder,
         rankClient: RankClient)
    {
        self.rewardsURLRepo = rewardsURLRepo
        self.rewardsClient = rewardsClient
        self.rewardsType = rewardsType
        self.superPropertyRecorder = superPropertyRecorder
        self.peoplePropertyRecorder = peoplePropertyRecorder
        rankClient.addDelegate(self)
    }

    func addDelegate(_ delegate: RewardsDelegate) {
        delegates.addListener(delegate)
    }

    func removeDelegate(_ delegate: RewardsDelegate) {
        delegates.removeListener(delegate)
    }

    func collectBadge(badge: Badge){
        lastCollectedBadge = badge
    }
}

// MARK: Widget Rewards

extension Rewards {
    func getPointsReward(for widgetID: String) {
        guard rewardsType != .noRewards else {
            delegates.publish { $0.rewards(noAwardsForWidget: widgetID) }
            return
        }

        guard let rewardsURL = rewardsURLRepo.get(id: widgetID) else {
            log.warning("Could not find the rewards_url for widget with id \(widgetID).")
            delegates.publish { $0.rewards(noAwardsForWidget: widgetID) }
            return
        }

        firstly {
            self.rewardsClient.getRewards(at: rewardsURL)
        }.then { rewardsResource in
            let newBadgeResource = rewardsResource.newBadges.max { b1, b2 in b1.points < b2.points }
            let newBadge: Badge? = Badge(from: newBadgeResource, rewardsType: self.rewardsType)
            let awards = Awards(points: Double(rewardsResource.newPoints), badges: newBadge)
            let awardsProfile: AwardsProfile = AwardsProfile(from: rewardsResource, rewardsType: self.rewardsType)

            self.lastEarnedBadge = Badge(from: rewardsResource.currentBadge)
            self.currentRank = rewardsResource.rank
            self.currentPoints = rewardsResource.totalPoints

            self.superPropertyRecorder.register({
                var superProperties: [SuperProperty] = [
                    .lifetimePoints(points: rewardsResource.totalPoints),
                    .pointsThisProgram(points: rewardsResource.points),
                    .badgeLevelThisProgram(level: awardsProfile.currentBadge?.level ?? 0),
                ]
                if newBadge != nil {
                    superProperties.append(.timeOfLastBadgeAward(time: Date()))
                }
                return superProperties
            }())
            self.peoplePropertyRecorder.record([.lifetimePoints(points: rewardsResource.totalPoints)])

            self.delegates.publish { $0.rewards(didReceiveAwards: awards, awardsProfile: awardsProfile, widgetID: widgetID) }

        }.catch { error in
            self.delegates.publish { $0.rewards(noAwardsForWidget: widgetID) }
            self.delegates.publish { $0.rewards(didRecieveError: error) }
        }
    }
}

extension Rewards: AwardsProfileDelegate {
    func awardsProfile(didUpdate awardsProfile: AwardsProfile) {
        self.lastEarnedBadge = awardsProfile.currentBadge
        self.lastCollectedBadge = awardsProfile.currentBadge
        self.currentRank = awardsProfile.rank
        self.currentPoints = Int(awardsProfile.totalPoints)
    }
}

// MARK: - Models

struct Badge {
    let id: String
    var name: String
    var pointsToUnlock: Double
    var imageURL: URL?
    var level: Int

    init(id: String, name: String, pointsToUnlock: Double, level: Int, imageURL: URL?) {
        self.id = id
        self.name = name
        self.pointsToUnlock = pointsToUnlock
        self.level = level
        self.imageURL = imageURL
    }

    init?(from badgeResource: APIRewardsClient.BadgeResource?, rewardsType: RewardsType = .pointsAndBadges) {
        guard let badgeResource = badgeResource else { return nil }
        guard rewardsType == .pointsAndBadges else { return nil }
        let imageURL = badgeResource.mimetype.isImage ? badgeResource.file : nil
        self.init(id: badgeResource.id,
                  name: badgeResource.name,
                  pointsToUnlock: Double(badgeResource.points),
                  level: badgeResource.level,
                  imageURL: imageURL)
    }
}

struct AwardsProfile {
    var lifetimePoints: Int
    var totalPoints: Double
    var currentBadge: Badge?
    var nextBadge: Badge?
    var previousBadge: Badge?
    var rank: Int?

    init(lifetimePoints: Int, totalPoints: Double, currentBadge: Badge?, nextBadge: Badge?, previousBadge: Badge?, rank: Int?) {
        self.lifetimePoints = lifetimePoints
        self.totalPoints = totalPoints
        self.currentBadge = currentBadge
        self.nextBadge = nextBadge
        self.previousBadge = previousBadge
        self.rank = rank
    }

    init(from rewardsResource: APIRewardsClient.RewardsResource, rewardsType: RewardsType) {
        switch rewardsType {
        case .noRewards:
            self.init(lifetimePoints: rewardsResource.totalPoints,
                      totalPoints: 0,
                      currentBadge: nil,
                      nextBadge: nil,
                      previousBadge: nil,
                      rank: rewardsResource.rank)
        case .pointsOnly:
            self.init(lifetimePoints: rewardsResource.totalPoints,
                      totalPoints: Double(rewardsResource.points),
                      currentBadge: nil,
                      nextBadge: nil,
                      previousBadge: nil,
                      rank: rewardsResource.rank)
        case .pointsAndBadges:
            self.init(lifetimePoints: rewardsResource.totalPoints,
                      totalPoints: Double(rewardsResource.points),
                      currentBadge: Badge(from: rewardsResource.currentBadge, rewardsType: rewardsType),
                      nextBadge: Badge(from: rewardsResource.nextBadge, rewardsType: rewardsType),
                      previousBadge: Badge(from: rewardsResource.previousBadge, rewardsType: rewardsType),
                      rank: rewardsResource.rank)
        }
    }

    init(from profileResource: ProfileResource) {
        self.init(lifetimePoints: profileResource.points,
                  totalPoints: 0, // Assume 0 because we do not get program points in our profile
                  currentBadge: Badge(from: profileResource.currentBadge),
                  nextBadge: nil,
                  previousBadge: nil,
                  rank: nil)
    }

    init(from rankResource: RankResource) {
        self.init(lifetimePoints: rankResource.totalPoints,
                  totalPoints: Double(rankResource.points),
                  currentBadge: Badge(from: rankResource.currentBadge),
                  nextBadge: Badge(from: rankResource.nextBadge),
                  previousBadge: Badge(from: rankResource.previousBadge),
                  rank: rankResource.rank)
    }
}

struct Awards {
    let points: Double?
    let badges: Badge?
}

protocol AwardsProfileVendor {
    func addDelegate(_ delegate: AwardsProfileDelegate)
    func removeDelegate(_ delegate: AwardsProfileDelegate)
}

protocol AwardsProfileDelegate: AnyObject {
    func awardsProfile(didUpdate awardsProfile: AwardsProfile)
}
