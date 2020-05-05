//
//  AlertWidgetContentView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

class AlertWidgetContentView: UIView {
    // MARK: UI Properties

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .left
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return label
    }()

    lazy var imageView: UIImageViewAligned = {
        let imageView = UIImageViewAligned()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var type: AlertWidgetViewType

    // MARK: Initialization

    init(type: AlertWidgetViewType) {
        self.type = type
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    // MARK: View setup and layout

    private func configure() {
        configureLayout()
    }

    private func configureLayout() {
        switch type {
        case .text:
            addConstraintsForTextOnly()
        case .image:
            addConstraintsForImageOnly()
        case .both:
            imageView.alignment = .right
            addConstraintsForTextAndImage()
        }
    }

    private func addConstraintsForTextOnly() {
        // Add subviews
        addSubview(textLabel)

        let constraints = [
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func addConstraintsForImageOnly() {
        // Add subviews
        addSubview(imageView)

        let constraints = [
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 90)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func addConstraintsForTextAndImage() {
        // Add subviews
        addSubview(textLabel)
        addSubview(imageView)

        let constraints = [
            heightAnchor.constraint(lessThanOrEqualToConstant: 90),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 120)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
