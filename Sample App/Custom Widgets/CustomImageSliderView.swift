//
//  CustomImageSliderView.swift
//  Sample App
//
//  Created by Jelzon Monzon on 1/6/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import UIKit

class CustomImageSliderView: UIView {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()

    let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let widgetTag: UILabel = {
        let label = UILabel()
        label.text = "EMOJI SLIDER"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
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

    let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        return slider
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(stackView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(bodyView)

        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 21).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -21).isActive = true

        headerView.addSubview(widgetTag)
        widgetTag.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        widgetTag.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        widgetTag.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        widgetTag.heightAnchor.constraint(equalToConstant: 12).isActive = true

        headerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: widgetTag.bottomAnchor, constant: 4).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18).isActive = true

        bodyView.addSubview(slider)
        slider.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
        slider.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 40).isActive = true
        slider.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor, constant: -40).isActive = true
        slider.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
