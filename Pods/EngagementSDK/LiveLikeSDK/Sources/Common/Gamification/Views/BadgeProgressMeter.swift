//
//  BadgeProgressMeter.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/29/19.
//

import UIKit

class BadgeProgressMeter: UIView {
    private var currentPoints: CGFloat = 0
    private var totalPointsForUnlock: CGFloat? = 100

    private var badgeImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()

    private var progressBackgroundTrack: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var goalLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var theme: Theme = Theme()

    init() {
        super.init(frame: .zero)
        configureLayout()
        setTheme(Theme())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BadgeProgressMeter {
    func animateProgressLabel(lhsStart: CGFloat, lhsEnd: CGFloat, rhs: CGFloat, animationDelay: TimeInterval){
        setProgressLabel(lhs: lhsStart, rhs: rhs)
        delay(animationDelay) {
            self.setProgressLabel(lhs: lhsEnd, rhs: rhs)
        }
    }
    
    func animateProgressBar(from: CGFloat, to: CGFloat, max: CGFloat, duration: TimeInterval, delay: TimeInterval){
        progressBar.animateProgress(from: from, to: to, max: max, duration: duration, delay: delay)
    }
    
    func setProgressLabel(lhs: CGFloat, rhs: CGFloat){
        progressLabel.setWidgetSecondaryText(lhs.toIntString, theme: theme, alignment: .right)
        goalLabel.setWidgetSecondaryText("/\(rhs.toIntString)", theme: theme, alignment: .left)
    }
    
    func setProgressBar(progress: CGFloat, max: CGFloat){
        progressBar.setProgress(from: 0, to: progress, max: max)
    }

    func setBadgeImage(_ image: UIImage) {
        badgeImageView.image = image
    }
}

// MARK: - Internal Methods

extension BadgeProgressMeter {
    func setTheme(_ theme: Theme) {
        self.theme = theme
        progressBackgroundTrack.backgroundColor = theme.widgetBodyColor
        progressBackgroundTrack.livelike_cornerRadius = theme.widgetCornerRadius
    }

    func badgeSpinAnimation() {
        badgeImageView.rotate360Degrees(duration: 0.3, completionDelegate: nil)
    }
}

// MARK: - Private Methods

private extension BadgeProgressMeter {
    func configureLayout() {
        addSubview(progressBackgroundTrack)
        addSubview(progressBar)
        addSubview(goalLabel)
        addSubview(progressLabel)
        addSubview(badgeImageView)

        NSLayoutConstraint.activate([
            badgeImageView.heightAnchor.constraint(equalTo: heightAnchor),
            badgeImageView.widthAnchor.constraint(equalTo: badgeImageView.heightAnchor),
            badgeImageView.centerXAnchor.constraint(equalTo: trailingAnchor),
            badgeImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            progressBackgroundTrack.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
            progressBackgroundTrack.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressBackgroundTrack.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBackgroundTrack.trailingAnchor.constraint(equalTo: trailingAnchor),

            goalLabel.leadingAnchor.constraint(equalTo: progressBackgroundTrack.centerXAnchor),
            goalLabel.topAnchor.constraint(equalTo: progressBackgroundTrack.topAnchor),
            goalLabel.bottomAnchor.constraint(equalTo: progressBackgroundTrack.bottomAnchor),
            goalLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),

            progressLabel.trailingAnchor.constraint(equalTo: progressBackgroundTrack.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: progressBackgroundTrack.topAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: progressBackgroundTrack.bottomAnchor),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ]
            + progressBar.fillConstraints(to: progressBackgroundTrack)
        )
    }
    
}

extension CGFloat {
    var toIntString: String {
        return String(format: "%.0f", self)
    }
}

// MARK: Common Composites

extension BadgeProgressMeter {
    /**
     Composite animation which is commonly used by other components.
     Progress label animates from total points earned to total points after points award towards next badge goal
     Progress bar animates from points earned towards next badge from current badge normalized at 0
     */
    func animate(viewModel: AwardsViewModel, labelDelay: TimeInterval){
        if viewModel.didEarnBadge {
            if let pointsToUnlockEarnedBadge = viewModel.totalPointsToUnlockEarnedBadge {
                self.animateProgressLabel(lhsStart: viewModel.pointsBeforeAward,
                                          lhsEnd: viewModel.pointsAfterAward,
                                          rhs: pointsToUnlockEarnedBadge,
                                          animationDelay: labelDelay)
            }
            if let max = viewModel.totalPointsToUnlockEarnedBadgeFromPreviousBadge {
                self.animateProgressBar(from: viewModel.totalPointsEarnedFromPreviousBadgeToNewBadge,
                                        to: viewModel.totalPointsEarnedFromPreviousBadgeToNewBadge + viewModel.newPointsEarned,
                                        max: max,
                                        duration: 0.2,
                                        delay: 0.4)
            }
        
        } else {
            if let pointsToNextBadge = viewModel.totalPointsToUnlockNextBadge {
                self.animateProgressLabel(lhsStart: viewModel.pointsBeforeAward,
                                          lhsEnd: viewModel.pointsAfterAward,
                                          rhs: pointsToNextBadge,
                                          animationDelay: labelDelay)
            }
            if let max = viewModel.totalPointsToUnlockNextBadgeFromCurrentBadge {
                self.animateProgressBar(
                    from: viewModel.totalPointsEarnedFromCurrentBadgeBeforeAward,
                    to: viewModel.totalPointsEarnedFromCurrentBadgeBeforeAward + viewModel.newPointsEarned,
                    max: max,
                    duration: 0.2,
                    delay: 0.4)
            }
        }
    }
    
    /**
     Composite setter method to initialize properties from an awardsViewModel
     */
    func set(viewModel: AwardsViewModel) {
        if viewModel.didEarnBadge {
            if let pointsToUnlockEarnedBadge = viewModel.totalPointsToUnlockEarnedBadge {
                setProgressLabel(lhs: viewModel.pointsBeforeAward,
                                 rhs: pointsToUnlockEarnedBadge)
            }
            if let max = viewModel.totalPointsToUnlockEarnedBadgeFromPreviousBadge {
                setProgressBar(
                    progress: viewModel.totalPointsEarnedFromPreviousBadgeToNewBadge,
                    max: max
                )
            }
            if let badgeImage = viewModel.newBadgeEarned?.desaturatedImage {
                setBadgeImage(badgeImage)
            }
        } else {
            if let pointsToUnlockNextBadge = viewModel.totalPointsToUnlockNextBadge {
                setProgressLabel(lhs: viewModel.pointsBeforeAward,
                                 rhs: pointsToUnlockNextBadge)
            }
            if let max = viewModel.totalPointsToUnlockNextBadgeFromCurrentBadge {
                setProgressBar(
                    progress: viewModel.totalPointsEarnedFromCurrentBadgeBeforeAward,
                    max: max
                )
            }
            if let badgeImage = viewModel.nextBadgeToUnlock?.desaturatedImage {
                setBadgeImage(badgeImage)
            }
        }
    }
}
