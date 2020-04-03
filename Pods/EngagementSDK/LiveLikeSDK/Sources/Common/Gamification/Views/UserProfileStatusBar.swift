//
//  UserProfileStatusBar.swift
//  EngagementSDK
//
//  Created by Jelzon WORK on 8/16/19.
//

import UIKit

class UserProfileStatusBar: UIView {
    private let nameBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        view.livelike_cornerRadius = 12
        return view
    }()
    
    private lazy var badgeWidthConstraint: NSLayoutConstraint = self.badgeImageView.widthAnchor.constraint(equalToConstant: 0)
    
    private let nameStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 2
        view.alignment = .center
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }()
    
    private let badgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var pointsAwardedAnimation: PointsAwardedAnimatedView = {
        let pointsAwardedAnimation = PointsAwardedAnimatedView(type: .userProfileStatus)
        pointsAwardedAnimation.translatesAutoresizingMaskIntoConstraints = false
        return pointsAwardedAnimation
    }()

    private let rankBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.livelike_cornerRadius = 4
        view.backgroundColor = .red
        view.isHidden = true
        return view
    }()

    private let rankLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.text = "EngagementSDK.gamification.Rank.phrase".localized()
        label.isHidden = true
        return label
    }()

    private let rank: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.accessibilityIdentifier = "label_user_rank"
        return label
    }()

    private var userRank: Int = 0 {
        didSet {
            rank.text = "#\(userRank)"
        }
    }

    init() {
        super.init(frame: .zero)
        configureLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveAward(notif:)), name: .didReceiveAwards, object: nil)
        configureAnimations()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configureAnimations(){
        badgeImageView.transform = .init(scaleX: 0, y: 0)
    }

    @objc private func didReceiveAward(notif: NSNotification) {
        if let awardsViewModel = notif.userInfo?["awardsModel"] as? AwardsViewModel {
            pointsAwardedAnimation.animate(from: awardsViewModel,
                                           duration: 0.6,
                                           coinDelay: 1.3,
                                           textDelay: 2.0)
            if let rank = awardsViewModel.rank {
                userRank = rank
            }
        }
    }

    private func configureLayout() {
        addSubview(nameBackground)
        nameBackground.addSubview(nameStackView)
        nameStackView.addArrangedSubview(nameLabel)
        nameStackView.addArrangedSubview(badgeImageView)
        addSubview(pointsAwardedAnimation)
        addSubview(rankBackground)
        rankBackground.addSubview(rankLabel)
        addSubview(rank)

        NSLayoutConstraint.activate([
            nameBackground.topAnchor.constraint(equalTo: topAnchor),
            nameBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            nameBackground.widthAnchor.constraint(greaterThanOrEqualTo: nameStackView.widthAnchor, multiplier: 1.0, constant: 16),
            nameBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            nameStackView.topAnchor.constraint(equalTo: nameBackground.topAnchor),
            nameStackView.bottomAnchor.constraint(equalTo: nameBackground.bottomAnchor),
            nameStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            nameStackView.leadingAnchor.constraint(equalTo: nameBackground.leadingAnchor, constant: 8),
            
            badgeWidthConstraint,
            badgeImageView.heightAnchor.constraint(equalTo: badgeImageView.widthAnchor),

            pointsAwardedAnimation.leadingAnchor.constraint(equalTo: nameBackground.trailingAnchor, constant: 10.0),
            pointsAwardedAnimation.heightAnchor.constraint(equalToConstant: 16.0),
            pointsAwardedAnimation.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            pointsAwardedAnimation.centerYAnchor.constraint(equalTo: centerYAnchor),

            rankBackground.heightAnchor.constraint(equalToConstant: 16.0),
            rankBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
            rankBackground.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            rankBackground.leadingAnchor.constraint(equalTo: pointsAwardedAnimation.trailingAnchor, constant: 10),

            rankLabel.leadingAnchor.constraint(equalTo: rankBackground.leadingAnchor, constant: 4),
            rankLabel.trailingAnchor.constraint(equalTo: rankBackground.trailingAnchor, constant: -4),
            rankLabel.topAnchor.constraint(equalTo: rankBackground.topAnchor),
            rankLabel.bottomAnchor.constraint(equalTo: rankBackground.bottomAnchor),

            rank.heightAnchor.constraint(equalToConstant: 16.0),
            rank.centerYAnchor.constraint(equalTo: centerYAnchor),
            rank.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            rank.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8.0)
        ])
    }
    
    private func setBadge(_ badge: BadgeViewModel){
        if let image = badge.image {
            badgeImageView.image = image
            badgeWidthConstraint.constant = 14
        }
    }
    
    private func animateFirstBadge(firstBadge: BadgeViewModel){
        firstly {
            UIView.animate(duration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                self.badgeWidthConstraint.constant = 14
                self.layoutIfNeeded()
            })
        }.then { _ -> Promise<Bool> in
            self.animateBadgeGrow(badge: firstBadge, duration: 0.5, delay: 0.5)
        }.catch { error in
            log.error(error.localizedDescription)
        }
    }
    
    private func animateReplaceBadge(newBadge: BadgeViewModel){
        self.badgeImageView.transform = .init(scaleX: 0, y: 0)
        firstly {
            animateBadgeGrow(badge: newBadge, duration: 0.5, delay: 0.0)
        }.catch { error in
            log.error(error.localizedDescription)
        }
    }

    private func animateRemoveBadge(){
        firstly {
            UIView.animate(duration: 0.2) {
                self.badgeImageView.transform = .init(scaleX: 0, y: 0)
            }
            }.then { _ -> Promise<Bool> in
                self.badgeImageView.image = nil
                return UIView.animate(duration: 0.3) {
                    self.badgeWidthConstraint.constant = 0
                }
            }.catch {
                log.error($0.localizedDescription)
        }
    }
    
    private func animateBadgeGrow(badge: BadgeViewModel,
                                  duration: TimeInterval,
                                  delay: TimeInterval) -> Promise<Bool>{
        self.badgeImageView.image = badge.image
        return UIView.animatePromise(withDuration: duration,
                                     delay: delay,
                                     usingSpringWithDamping: 0.5,
                                     initialSpringVelocity: 0,
                                     options: .curveEaseInOut,
                                     animations: {
                        self.badgeImageView.transform = .identity
        })
    }
}

// MARK: - Setters

extension UserProfileStatusBar {

    var displayName: String {
        get { return nameLabel.text ?? "" }
        set { nameLabel.text = newValue }
    }

    func setRankPhrase(rankPhrase: String) {
        rankLabel.text = rankPhrase
    }

    func setUserRank(userRank: Int?) {
        if let userRank = userRank {
            self.userRank = userRank
            self.rankBackground.isHidden = false
            self.rankLabel.isHidden = false
            self.rank.isHidden = false
        } else {
            self.rankBackground.isHidden = true
            self.rankLabel.isHidden = true
            self.rank.isHidden = true
        }
    }

    func setTheme(_ theme: Theme) {
        nameLabel.font = theme.fontPrimary.maxAccessibilityFontSize(size: 30.0)
        rankLabel.font = theme.rankTextFont.maxAccessibilityFontSize(size: 20.0)
        rank.font = theme.fontSecondary.maxAccessibilityFontSize(size: 20.0)
        rankLabel.textColor = theme.rankTextColor
        rankBackground.backgroundColor = theme.rankBackgroundColor
        pointsAwardedAnimation.setTheme(theme)
    }

    func updateRewardPoints(viewModel: AwardsViewModel) {
        pointsAwardedAnimation.animate(from: viewModel,
                                       duration: 0.6,
                                       coinDelay: 1.3,
                                       textDelay: 2.0)
    }

    func setUserRewardPoints(points: Int?) {
        if let points = points {
            pointsAwardedAnimation.isHidden = false
            let viewModel = AwardsViewModel.create(profileBeforeNewAwards: AwardsProfile(lifetimePoints: points,
                                                                                         totalPoints: Double(points),
                                                                                         currentBadge: nil,
                                                                                         nextBadge: nil,
                                                                                         previousBadge: nil, rank: nil),
                                                   newAwards: Awards(points: nil, badges: nil),
                                                   rewards: nil)
            pointsAwardedAnimation.set(from: viewModel)
        
        } else {
            pointsAwardedAnimation.isHidden = true
        }
    }

    func set(viewModel: AwardsViewModel) {
        if let currentBadge = viewModel.currentBadge {
            badgeImageView.transform = .identity
            badgeWidthConstraint.constant = 14
            badgeImageView.image = currentBadge.image
        }
    }
    
    func animate(viewModel: AwardsViewModel) {
        if let currentBadge = viewModel.currentBadge {
            setBadge(badgeViewModel: currentBadge)
        }
    }
    
    func setBadge(badgeViewModel: BadgeViewModel?) {
        guard let badgeViewModel = badgeViewModel else {
            animateRemoveBadge()
            return
        }

        if self.badgeImageView.image == nil {
            self.animateFirstBadge(firstBadge: badgeViewModel)
        } else {
            self.animateReplaceBadge(newBadge: badgeViewModel)
        }
    }
}
