//
//  CustomWidgetOptionsView.swift
//  Sample App
//
//  Created by Mike Moloksher on 1/12/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import UIKit

class CustomWidgetOptionsView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let widgetTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "IMAGE PREDICTION"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let bodyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var choicesCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CustomImageOptionCell.self, forCellWithReuseIdentifier: "myCell")
        collectionView.backgroundColor = .white
        return collectionView
    }()

    let widgetBarTimer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    init() {
        super.init(frame: .zero)
    }

    init(
        title: String,
        widgetType: String,
        optionAmount: Int
    ) {
        super.init(frame: .zero)

        backgroundColor = .white
        addSubview(widgetBarTimer)
        NSLayoutConstraint.activate([
            widgetBarTimer.topAnchor.constraint(equalTo: self.topAnchor),
            widgetBarTimer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            widgetBarTimer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            widgetBarTimer.heightAnchor.constraint(equalToConstant: 5)
        ])

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 21),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -21)
        ])

        stackView.addArrangedSubview(headerView)
        headerView.addSubview(widgetTypeLabel)
        NSLayoutConstraint.activate([
            widgetTypeLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            widgetTypeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            widgetTypeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            widgetTypeLabel.heightAnchor.constraint(equalToConstant: 12)
        ])

        headerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: widgetTypeLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18)
        ])

        stackView.addArrangedSubview(bodyView)
        bodyView.addSubview(choicesCollectionView)
        NSLayoutConstraint.activate([
            choicesCollectionView.topAnchor.constraint(equalTo: bodyView.topAnchor),
            choicesCollectionView.widthAnchor.constraint(equalTo: bodyView.widthAnchor),
            choicesCollectionView.centerXAnchor.constraint(equalTo: bodyView.centerXAnchor),
            choicesCollectionView.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor)
        ])

        widgetTypeLabel.text = widgetType.uppercased()
        titleLabel.text = title

        if optionAmount > 2 {
            bodyView.heightAnchor.constraint(equalToConstant: 130).isActive = true
        } else {
            bodyView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }

        layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

