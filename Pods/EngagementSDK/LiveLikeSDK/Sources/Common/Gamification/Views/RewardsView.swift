//
//  RewardsView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/30/19.
//

import UIKit

protocol RewardsView {
    func apply(viewModel: AwardsViewModel, animated: Bool)
}

class BadgeViewModel {
    var innerBadge: Badge
    var name: String
    var image: UIImage?
    lazy var desaturatedImage: UIImage? = {
        guard let cgImage = image?.cgImage else { return nil}
        return UIImage(cgImage: cgImage).withSaturationAdjustment(byVal: 0)
    }()
    var pointsToUnlock: CGFloat
    var rewards: Rewards?

    convenience init?(from badge: Badge?, rewards: Rewards?) {
        guard let badge = badge else { return nil }
        self.init(from: badge)
        self.rewards = rewards
    }

    private init(from badge: Badge) {
        innerBadge = badge
        name = badge.name
        if let imageURL = badge.imageURL {
            do {
                image = try UIImage(data: Data(contentsOf: imageURL))
            } catch {
                log.error("Failed to load badge image from \(imageURL)")
            }
        }
        pointsToUnlock = CGFloat(badge.pointsToUnlock)
    }

    func collect(){
        rewards?.collectBadge(badge: innerBadge)
    }
}

struct AwardsViewModel {
    var pointsImage: UIImage
    var pointsAfterAward: CGFloat
    var pointsBeforeAward: CGFloat {
        return pointsAfterAward - newPointsEarned
    }

    var newPointsEarned: CGFloat

    var currentBadge: BadgeViewModel?
    var previousBadge: BadgeViewModel?
    var nextBadgeToUnlock: BadgeViewModel?
    var newBadgeEarned: BadgeViewModel?
    var rank: Int?
    var didEarnBadge: Bool {
        return newBadgeEarned != nil
    }

    var rewards: Rewards?
    
    var totalPointsToUnlockNextBadge: CGFloat? {
        return nextBadgeToUnlock?.pointsToUnlock
    }

    var totalPointsToUnlockEarnedBadge: CGFloat? {
        return newBadgeEarned?.pointsToUnlock
    }
    
    var totalPointsToUnlockCurrentBadge: CGFloat {
        return currentBadge?.pointsToUnlock ?? 0
    }

    var totalPointsToUnlockPreviousBadge: CGFloat {
        return previousBadge?.pointsToUnlock ?? 0
    }

    var totalPointsEarnedFromCurrentBadgeBeforeAward: CGFloat {
        return pointsBeforeAward - totalPointsToUnlockCurrentBadge
    }

    var totalPointsEarnedFromPreviousBadgeToNewBadge: CGFloat {
        return pointsBeforeAward - totalPointsToUnlockPreviousBadge
    }

    var totalPointsToUnlockEarnedBadgeFromPreviousBadge: CGFloat? {
        guard let newBadgePoints = newBadgeEarned?.pointsToUnlock else { return nil }
        return newBadgePoints - totalPointsToUnlockPreviousBadge
    }

    var totalPointsToUnlockNextBadgeFromCurrentBadge: CGFloat? {
        guard let nextBadgePoints = nextBadgeToUnlock?.pointsToUnlock else { return nil }
        return nextBadgePoints - totalPointsToUnlockCurrentBadge
    }

    static func create(profileBeforeNewAwards awardsProfile: AwardsProfile, newAwards: Awards, rewards: Rewards?) -> AwardsViewModel {
        return AwardsViewModel(pointsImage: UIImage(named: "coin", in: Bundle(for: EngagementSDK.self), compatibleWith: nil)!,
                               pointsAfterAward: CGFloat(awardsProfile.totalPoints),
                               newPointsEarned: CGFloat(newAwards.points ?? 0),
                               currentBadge: BadgeViewModel(from: awardsProfile.currentBadge, rewards: rewards),
                               previousBadge: BadgeViewModel(from: awardsProfile.previousBadge, rewards: rewards),
                               nextBadgeToUnlock: BadgeViewModel(from: awardsProfile.nextBadge, rewards: rewards),
                               newBadgeEarned: BadgeViewModel(from: newAwards.badges, rewards: rewards),
                               rank: awardsProfile.rank,
                               rewards: rewards,
                               customData: nil)
    }
    
    let customData: String?
}
