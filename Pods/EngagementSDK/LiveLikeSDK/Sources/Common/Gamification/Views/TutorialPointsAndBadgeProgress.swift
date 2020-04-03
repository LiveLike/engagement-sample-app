//
//  TutorialPointsAndBadgeProgress.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/8/19.
//

import UIKit

class TutorialPointsAndBadgeProgress: UIView {
    private var badgeProgressMeter: BadgeProgressMeter = {
        let progressMeter = BadgeProgressMeter()
        progressMeter.translatesAutoresizingMaskIntoConstraints = false
        return progressMeter
    }()

    private var pointsAwardedAnimation: PointsAwardedAnimatedView = {
        let pointsAwardedAnimation = PointsAwardedAnimatedView(type: .widgetAward)
        pointsAwardedAnimation.translatesAutoresizingMaskIntoConstraints = false
        return pointsAwardedAnimation
    }()

    init() {
        super.init(frame: .zero)
        configureLayout()
        animationInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func animationInit() {
        badgeProgressMeter.alpha = 0
        badgeProgressMeter.transform = badgeProgressMeter.transform.translatedBy(x: 0, y: 10)
    }

    private func configureLayout() {
        addSubview(badgeProgressMeter)
        addSubview(pointsAwardedAnimation)
        NSLayoutConstraint.activate([
            pointsAwardedAnimation.centerXAnchor.constraint(equalTo: centerXAnchor),
            pointsAwardedAnimation.centerYAnchor.constraint(equalTo: centerYAnchor),
            pointsAwardedAnimation.heightAnchor.constraint(equalTo: heightAnchor, constant: -10),
            pointsAwardedAnimation.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)

        ] + badgeProgressMeter.fillConstraints(to: self))
    }

    private func playPointsAndBadgeAnimation(_ viewModel: AwardsViewModel) {
        firstly { () -> Promise<Bool> in
            self.pointsAwardedAnimation.animate(from: viewModel,
                                                duration: 0.6,
                                                coinDelay: 0.8,
                                                textDelay: 0)
            return Promise(value: true)
        }.then { _ in
            UIView.animate(duration: 0.4, delay: 2.0, options: [], animations: {
                self.pointsAwardedAnimation.alpha = 0
                self.pointsAwardedAnimation.transform = self.pointsAwardedAnimation.transform.translatedBy(x: 0, y: 10)
            })
        }.then { _ in
            UIView.animate(duration: 0.4, animations: {
                self.badgeProgressMeter.alpha = 1
                self.badgeProgressMeter.transform = .identity
            })
        }.then { _ in
            if let newBadge = viewModel.newBadgeEarned {
                delay(0.6) { [weak self] in
                    if let badgeImage = newBadge.image {
                        self?.badgeProgressMeter.setBadgeImage(badgeImage)
                    }
                    self?.badgeProgressMeter.badgeSpinAnimation()
                }
            }
            self.badgeProgressMeter.animate(viewModel: viewModel, labelDelay: 0.6)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    private func playPointsAnimation(_ viewModel: AwardsViewModel) {
        self.pointsAwardedAnimation.animate(from: viewModel,
                                            duration: 0.6,
                                            coinDelay: 0.8,
                                            textDelay: 0)
    }
}

extension TutorialPointsAndBadgeProgress {
    func setTheme(_ theme: Theme) {
        badgeProgressMeter.setTheme(theme)
        pointsAwardedAnimation.setTheme(theme)
    }
}

extension TutorialPointsAndBadgeProgress: RewardsView {
    func apply(viewModel: AwardsViewModel, animated: Bool) {
        badgeProgressMeter.set(viewModel: viewModel)

        guard animated else { return }

        if viewModel.nextBadgeToUnlock == nil, viewModel.didEarnBadge == false {
            playPointsAnimation(viewModel)
        } else {
            playPointsAndBadgeAnimation(viewModel)
        }
    }
}
