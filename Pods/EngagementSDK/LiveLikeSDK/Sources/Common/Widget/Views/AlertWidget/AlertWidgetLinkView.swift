//
//  AlertWidgetButton.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

class AlertWidgetLinkView: UIView {
    // MARK: UI Properties

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        label.textAlignment = .left
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return label
    }()

    lazy var rightArrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "widget_alert_right_arrow"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "widget_alert_right_arrow", in: Bundle(for: AlertWidgetLinkView.self), compatibleWith: nil)
        imageView.image = image
        return imageView
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
        configureLayout()
    }

    private func configureLayout() {
        // Add subviews
        addSubview(titleLabel)
        addSubview(rightArrowImageView)

        // Title Label
        let constraints = [
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: rightArrowImageView.leadingAnchor),
            rightArrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rightArrowImageView.widthAnchor.constraint(equalToConstant: 10),
            rightArrowImageView.heightAnchor.constraint(equalToConstant: 10),
            rightArrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 32)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
