//
//  AlertWidgetTitleView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

class AlertWidgetTitleView: UIView {
    // MARK: UI Properties

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return label
    }()

    lazy var gradientView: GradientView = {
        let gradientView = GradientView(orientation: .horizontal)
        gradientView.livelike_startColor = #colorLiteral(red: 0.6235294118, green: 0.01568627451, blue: 0.1058823529, alpha: 1)
        gradientView.livelike_endColor = #colorLiteral(red: 0.9607843137, green: 0.3176470588, blue: 0.3725490196, alpha: 1)
        return gradientView
    }()

    // MARK: Initialization

    init() {
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    // MARK: View setup and layout

    private func configure() {
        configureView()
        configureLayout()
    }

    private func configureView() {
        livelike_cornerRadius = 4
        livelike_shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        livelike_shadowOpacity = 0.2
        livelike_shadowRadius = 6
        livelike_shadowOffset = CGSize(width: 0, height: 6)
        clipsToBounds = true

        addSubview(gradientView)
        addSubview(titleLabel)
    }

    private func configureLayout() {
        // Gradient View
        gradientView.constraintsFill(to: self)

        // Title Label
        let constraints = [
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
