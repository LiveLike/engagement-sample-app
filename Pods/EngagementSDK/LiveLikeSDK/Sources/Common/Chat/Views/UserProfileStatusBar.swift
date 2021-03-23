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
    
    init() {
        super.init(frame: .zero)
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        addSubview(nameBackground)
        nameBackground.addSubview(nameStackView)
        nameStackView.addArrangedSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameBackground.topAnchor.constraint(equalTo: topAnchor),
            nameBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            nameBackground.widthAnchor.constraint(greaterThanOrEqualTo: nameStackView.widthAnchor, multiplier: 1.0, constant: 16),
            nameBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            nameStackView.topAnchor.constraint(equalTo: nameBackground.topAnchor),
            nameStackView.bottomAnchor.constraint(equalTo: nameBackground.bottomAnchor),
            nameStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            nameStackView.leadingAnchor.constraint(equalTo: nameBackground.leadingAnchor, constant: 8),
        ])
    }
}

// MARK: - Setters

extension UserProfileStatusBar {
    var displayName: String {
        get { return nameLabel.text ?? "" }
        set { nameLabel.text = newValue }
    }

    func setTheme(_ theme: Theme) {
        nameLabel.font = theme.fontPrimary.maxAccessibilityFontSize(size: 30.0)
    }
}
