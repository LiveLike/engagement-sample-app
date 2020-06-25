//
//  DialogWidgetView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/5/19.
//

import Lottie
import UIKit

class DialogWidgetView: UIView {
    var coreWidgetView = CoreWidgetView()

    var body: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()

    var title: UILabel = {
        let label = UILabel()
        label.text = "EngagementSDK.widget.DismissWidget.title".localized(withComment: "Title copy of DismissWidget").uppercased()
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lottieAnimationName: String
    
    private lazy var lottieView: AnimationView = {
        let image = AnimationView(name: self.lottieAnimationName, bundle: Bundle(for: DialogWidgetView.self))
        image.loopMode = .loop
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var noButton: GradientButton = {
        let button = GradientButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var forNowButton: GradientButton = {
        let button = GradientButton()
        button.backgroundColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var foreverButton: GradientButton = {
        let button = GradientButton()
        button.backgroundColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(lottieAnimationName: String) {
        self.lottieAnimationName = lottieAnimationName
        super.init(frame: .zero)
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    func playEmojiAnimation() {
        self.lottieView.play()
    }

    private func configureLayout() {
        addSubview(coreWidgetView)

        coreWidgetView.headerView = nil
        coreWidgetView.contentView = body
        coreWidgetView.footerView = nil

        let buttonStackView = UIStackView(arrangedSubviews: [noButton, forNowButton, foreverButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fillEqually
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 6
        buttonStackView.backgroundColor = .blue

        body.addSubview(title)
        body.addSubview(lottieView)
        body.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            body.heightAnchor.constraint(equalToConstant: 138),

            title.leadingAnchor.constraint(equalTo: body.leadingAnchor, constant: 16),
            title.topAnchor.constraint(equalTo: body.topAnchor, constant: 25),
            title.trailingAnchor.constraint(equalTo: lottieView.leadingAnchor, constant: -20),
            title.heightAnchor.constraint(equalToConstant: 40),

            lottieView.trailingAnchor.constraint(equalTo: body.trailingAnchor, constant: -20),
            lottieView.topAnchor.constraint(equalTo: body.topAnchor, constant: 20),
            lottieView.widthAnchor.constraint(equalToConstant: 50),
            lottieView.heightAnchor.constraint(equalToConstant: 50),

            buttonStackView.leadingAnchor.constraint(equalTo: body.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: body.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: body.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
}

class GradientButton: UIButton {
    var gradient = GradientView(orientation: .horizontal)

    init() {
        super.init(frame: .zero)
        insertSubview(gradient, at: 0)
        clipsToBounds = true
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.constraintsFill(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
