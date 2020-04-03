//
//  WidgetPointsAndBadgeProgress.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/30/19.
//

import UIKit

class WidgetPointsAndBadgeProgress: UIView {
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

    private var badgeEarnedMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "placeholder"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

        pointsAwardedAnimation.alpha = 0
        pointsAwardedAnimation.transform = pointsAwardedAnimation.transform.translatedBy(x: 0, y: 10)

        badgeEarnedMessageLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }

    private func configureLayout() {
        addSubview(badgeProgressMeter)
        addSubview(pointsAwardedAnimation)
        addSubview(badgeEarnedMessageLabel)

        NSLayoutConstraint.activate([
            pointsAwardedAnimation.centerXAnchor.constraint(equalTo: centerXAnchor),
            pointsAwardedAnimation.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 3 / 5),
            pointsAwardedAnimation.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeProgressMeter.leadingAnchor.constraint(equalTo: leadingAnchor),
            badgeProgressMeter.trailingAnchor.constraint(equalTo: trailingAnchor),
            badgeProgressMeter.heightAnchor.constraint(equalTo: heightAnchor),
            badgeProgressMeter.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeEarnedMessageLabel.topAnchor.constraint(equalTo: badgeProgressMeter.bottomAnchor),
            badgeEarnedMessageLabel.heightAnchor.constraint(equalToConstant: 15),
            badgeEarnedMessageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            badgeEarnedMessageLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func playPointsAndBadgeAnimation(_ viewModel: AwardsViewModel) {
        firstly {
            UIView.animate(duration: 0.3, animations: {
                self.badgeProgressMeter.alpha = 1
                self.badgeProgressMeter.transform = .identity
            })
        }.then { _ in
            UIView.animate(duration: 0.3, delay: 0.3, options: [], animations: {
                self.pointsAwardedAnimation.alpha = 1
                self.pointsAwardedAnimation.transform = self.pointsAwardedAnimation.transform.translatedBy(x: 0, y: -self.badgeProgressMeter.bounds.height)
            })
        }.then { _ in
            self.badgeProgressMeter.animate(viewModel: viewModel, labelDelay: 0.4)
            self.pointsAwardedAnimation.animate(from: viewModel,
                                                duration: 0.6,
                                                coinDelay: 0.3,
                                                textDelay: 0)
        }.then { (_) -> Promise<Bool> in
            if let newBadge = viewModel.newBadgeEarned {
                delay(0.6) { [weak self] in
                    if let badgeImage = newBadge.image {
                        self?.badgeProgressMeter.setBadgeImage(badgeImage)
                    }
                    self?.badgeProgressMeter.badgeSpinAnimation()
                }
                return UIView.animatePromise(withDuration: 0.6, delay: 0.6, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut) {
                    self.badgeEarnedMessageLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            } else {
                return Promise(value: true)
            }
        }.then { _ -> Promise<Bool> in
            return UIView.animate(duration: 0.3, delay: 0.7, options: [], animations: {
                self.pointsAwardedAnimation.alpha = 0
                self.pointsAwardedAnimation.transform = .identity
            })
        }.then { _ in
            UIView.animate(duration: 0.3, delay: 0.7, options: [], animations: {
                self.badgeProgressMeter.alpha = 0
                self.badgeProgressMeter.transform = self.badgeProgressMeter.transform.translatedBy(x: 0, y: 10)
                self.badgeEarnedMessageLabel.alpha = 0
            })
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    private func playPointsOnlyAnimation(_ viewModel: AwardsViewModel) {
        firstly {
            UIView.animate(duration: 0.3, delay: 0.3, options: [], animations: {
                self.pointsAwardedAnimation.alpha = 1
                self.pointsAwardedAnimation.transform = .identity
            })
        }.then { _ in
            self.pointsAwardedAnimation.animate(from: viewModel,
                                                duration: 0.6,
                                                coinDelay: 0.4,
                                                textDelay: 0)
        }.then { _ -> Promise<Bool> in
            UIView.animate(duration: 0.3, delay: 3.4, options: [], animations: {
                self.pointsAwardedAnimation.alpha = 0
                self.pointsAwardedAnimation.transform = self.pointsAwardedAnimation.transform.translatedBy(x: 0, y: 10)
            })
        }.catch {
            log.error($0.localizedDescription)
        }
    }
}

extension WidgetPointsAndBadgeProgress {
    func setTheme(_ theme: Theme) {
        badgeProgressMeter.setTheme(theme)
        pointsAwardedAnimation.setTheme(theme)
        badgeEarnedMessageLabel.setWidgetSecondaryText("New Badge!!!".uppercased(), theme: theme)
    }
}

extension WidgetPointsAndBadgeProgress: RewardsView {
    func apply(viewModel: AwardsViewModel, animated: Bool) {
        badgeProgressMeter.set(viewModel: viewModel)

        guard animated else { return }

        if viewModel.nextBadgeToUnlock == nil, viewModel.didEarnBadge == false {
            playPointsOnlyAnimation(viewModel)
        } else {
            playPointsAndBadgeAnimation(viewModel)
        }
    }
}
