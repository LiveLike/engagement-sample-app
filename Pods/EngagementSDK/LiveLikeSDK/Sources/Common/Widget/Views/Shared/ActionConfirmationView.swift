//
//  ActionConfirmationView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-05.
//

import Lottie
import UIKit

class ActionConfirmationView: UIView {
    // MARK: Private Properties

    private let title: String
    private let animationID: String
    private var duration: Double
    private let completion: () -> Void

    // MARK: Views

    var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = self.title
        label.textColor = .white
        return label
    }()

    private lazy var animationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Initialization

    init(title: String, animationID: String, duration: Double, completion: @escaping (() -> Void)) {
        self.title = title
        self.animationID = animationID
        self.duration = duration
        self.completion = completion
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        startTimer()
    }

    // MARK: Private Functions - View Setup

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        configureBackground()
        configureAnimationView()
        configureTitleLabel()
        configureLayout()
    }

    private func configureBackground() {
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor(rInt: 0, gInt: 0, bInt: 0, alpha: 0.8)

        let constraints = [
            backgroundView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func configureTitleLabel() {
        addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = title
    }

    private func configureAnimationView() {
        addSubview(animationView)
        let lottieView = AnimationView(name: animationID, bundle: Bundle(for: ActionConfirmationView.self))
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopMode = .loop

        animationView.addSubview(lottieView)
        lottieView.constraintsFill(to: animationView)

        lottieView.play()
    }

    private func configureLayout() {
        let constraints = [
            titleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            backgroundView.topAnchor.constraint(equalTo: animationView.centerYAnchor, constant: 0),
            backgroundView.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 40),
            animationView.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 10)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func startTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.completion()
        }
    }
}

extension ActionConfirmationView {
    func customize(theme: Theme) {
        titleLabel.font = theme.fontSecondary
        titleLabel.textColor = theme.widgetFontSecondaryColor
        backgroundView.layer.cornerRadius = theme.widgetCornerRadius
    }
}
