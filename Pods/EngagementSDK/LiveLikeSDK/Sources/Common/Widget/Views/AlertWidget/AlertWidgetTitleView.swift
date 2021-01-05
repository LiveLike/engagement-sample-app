//
//  AlertWidgetTitleView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

class AlertWidgetTitleView: ThemeableView {
    // MARK: UI Properties
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        label.textAlignment = .left
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return label
    }()

    // MARK: Initialization

    override init() {
        super.init()
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
        clipsToBounds = true
        addSubview(titleLabel)
    }

    private func configureLayout() {
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
