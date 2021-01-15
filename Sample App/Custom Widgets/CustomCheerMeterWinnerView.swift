//
//  CustomCheerMeterWinnerView.swift
//  LiveLikeTestApp
//
//  Created by Jelzon Monzon on 1/14/21.
//

import Lottie
import UIKit

class CustomCheerMeterWinnerView: UIView {
    let winnerAnimationView: AnimationView = {
        let animationView = AnimationView(name: "win-1")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    let winnerImageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        view.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0).cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let winnerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init() {
        super.init(frame: .zero)

        addSubview(winnerImageContainer)
        addSubview(winnerAnimationView)
        winnerImageContainer.addSubview(winnerImageView)

        NSLayoutConstraint.activate([
            winnerImageContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            winnerImageContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            winnerImageContainer.widthAnchor.constraint(equalToConstant: 120),
            winnerImageContainer.heightAnchor.constraint(equalToConstant: 120),

            winnerImageView.topAnchor.constraint(equalTo: winnerImageContainer.topAnchor, constant: 20),
            winnerImageView.leadingAnchor.constraint(equalTo: winnerImageContainer.leadingAnchor, constant: 20),
            winnerImageView.trailingAnchor.constraint(equalTo: winnerImageContainer.trailingAnchor, constant: -20),
            winnerImageView.bottomAnchor.constraint(equalTo: winnerImageContainer.bottomAnchor, constant: -20),

            winnerAnimationView.topAnchor.constraint(equalTo: topAnchor),
            winnerAnimationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            winnerAnimationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            winnerAnimationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
