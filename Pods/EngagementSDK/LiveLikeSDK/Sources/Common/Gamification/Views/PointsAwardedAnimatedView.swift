//
//  PointsAwardedAnimatedView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/29/19.
//

import UIKit

enum PointsAwardedAnimatedViewType {
    case userProfileStatus
    case widgetAward

    var leadingMargin: CGFloat {
        switch self {
        case .userProfileStatus:
            return 4.0
        case .widgetAward:
            return 2.0
        }
    }
}

class PointsAwardedAnimatedView: UIView {
    private var poppingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var droppingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var pointsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.accessibilityIdentifier = "label_user_points_earned"
        return label
    }()

    private var theme: Theme = Theme()
    private var viewType: PointsAwardedAnimatedViewType

    init(type: PointsAwardedAnimatedViewType) {
        viewType = type
        super.init(frame: .zero)
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        addSubview(droppingImageView)
        addSubview(poppingImageView)
        addSubview(pointsLabel)

        NSLayoutConstraint.activate([
            poppingImageView.heightAnchor.constraint(equalToConstant: 14.0),
            poppingImageView.widthAnchor.constraint(equalTo: poppingImageView.heightAnchor),
            poppingImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            poppingImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            droppingImageView.heightAnchor.constraint(equalToConstant: 14.0),
            droppingImageView.widthAnchor.constraint(equalTo: droppingImageView.heightAnchor),
            droppingImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            droppingImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            pointsLabel.leadingAnchor.constraint(equalTo: poppingImageView.trailingAnchor, constant: viewType.leadingMargin),
            pointsLabel.heightAnchor.constraint(equalTo: heightAnchor),
            pointsLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            pointsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            pointsLabel.trailingAnchor.constraint(equalTo: trailingAnchor)

        ])
    }

    func set(from viewModel: AwardsViewModel) {
        poppingImageView.image = viewModel.pointsImage
        droppingImageView.image = viewModel.pointsImage
        
        setText(from: viewModel)
    }
    
    func animate(from viewModel: AwardsViewModel, duration: TimeInterval, coinDelay: TimeInterval, textDelay: TimeInterval){
        poppingImageView.image = viewModel.pointsImage
        droppingImageView.image = viewModel.pointsImage
        
        textAnimation(from: viewModel, delay: textDelay)
        coinDropAnimaton(duration: duration, delay: coinDelay)
    }
    
    private func coinDropAnimaton(duration: TimeInterval, delay: TimeInterval) {
        var droppingImageYTransform: CGFloat
        switch viewType {
        case .userProfileStatus:
            // reverse the animation for coins to go up
            droppingImageYTransform = -droppingImageView.bounds.height
        case .widgetAward:
            droppingImageYTransform = droppingImageView.bounds.height
        }

        // pop
        UIView.animate(withDuration: duration / 3, delay: delay, options: .repeat, animations: {
            UIView.setAnimationRepeatCount(3)
            self.poppingImageView.transform = self.poppingImageView.transform.scaledBy(x: 1.2, y: 1.2)
        }, completion: { _ in
            self.poppingImageView.transform = .identity
        })

        // drop
        droppingImageView.isHidden = false
        UIView.animate(withDuration: duration / 3, delay: delay, options: .repeat, animations: {
            UIView.setAnimationRepeatCount(3)
            self.droppingImageView.transform = self.droppingImageView.transform.translatedBy(x: 0, y: droppingImageYTransform)
        }, completion: { _ in
            self.droppingImageView.isHidden = true
            self.droppingImageView.transform = .identity
        })
    }
    
    private func textAnimation(from viewModel: AwardsViewModel, delay: TimeInterval){
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.setText(from: viewModel)
        }
    }
    
    private func setText(from viewModel: AwardsViewModel){
        switch self.viewType {
        case .userProfileStatus:
            self.pointsLabel.text = "\(Int(viewModel.pointsAfterAward).description)"
        case .widgetAward:
            self.pointsLabel.text = "+\(Int(viewModel.newPointsEarned).description)"
        }
    }
}

extension PointsAwardedAnimatedView {
    func setTheme(_ theme: Theme) {
        self.theme = theme
        
        switch viewType {
        case .userProfileStatus:
            self.pointsLabel.font = theme.fontSecondary.maxAccessibilityFontSize(size: 20.0)
        case .widgetAward:
            self.pointsLabel.font = theme.popupTitleFont.maxAccessibilityFontSize(size: 20.0)
        }
        self.pointsLabel.textColor = theme.popupTitleColor
    }
}
