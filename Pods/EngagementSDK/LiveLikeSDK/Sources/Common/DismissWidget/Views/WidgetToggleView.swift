//
//  WidgetToggleView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/7/19.
//

import UIKit

class WidgetToggleView: UIView {
    var toggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var mutedImage: UIImage = {
        guard let image = UIImage(named: "icWidgetoff", in: Bundle(for: WidgetToggleView.self), compatibleWith: nil) else {
            assertionFailure("Failed to load the image icWidgetoff from resources")
            return UIImage()
        }
        return image
    }()

    var unmutedImage: UIImage = {
        guard let image = UIImage(named: "icWidgeton", in: Bundle(for: WidgetToggleView.self), compatibleWith: nil) else {
            assertionFailure("Failed to load the image icWidgeton from resources")
            return UIImage()
        }
        return image
    }()

    var tagBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        return view
    }()

    var tagLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let widgetsText = NSMutableAttributedString("EngagementSDK.widget.DismissWidget.widget".localized(), font: UIFont.systemFont(ofSize: 12, weight: .bold), color: .white, lineSpacing: 0)
        widgetsText.append(NSMutableAttributedString(" \("EngagementSDK.widget.DismissWidget.off".localized())", font: UIFont.systemFont(ofSize: 12, weight: .bold), color: .red, lineSpacing: 0))
        label.attributedText = widgetsText
        return label
    }()

    init() {
        super.init(frame: .zero)
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    private func configureLayout() {
        addSubview(toggleButton)
        addSubview(tagBackground)
        tagBackground.addSubview(tagLabel)

        NSLayoutConstraint.activate([
            toggleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            toggleButton.topAnchor.constraint(equalTo: topAnchor),
            toggleButton.heightAnchor.constraint(equalToConstant: 24),
            toggleButton.widthAnchor.constraint(equalToConstant: 24),

            tagLabel.centerXAnchor.constraint(equalTo: tagBackground.centerXAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: tagBackground.centerYAnchor),

            tagBackground.trailingAnchor.constraint(equalTo: toggleButton.leadingAnchor, constant: -10),
            tagBackground.centerYAnchor.constraint(equalTo: toggleButton.centerYAnchor),
            tagBackground.heightAnchor.constraint(equalToConstant: 24),
            tagBackground.widthAnchor.constraint(greaterThanOrEqualTo: tagLabel.widthAnchor, constant: 20)

        ])
    }

    func showMuteButton() {
        toggleButton.setImage(mutedImage, for: .normal)
    }

    func showUnmuteButton() {
        toggleButton.setImage(unmutedImage, for: .normal)
    }
}
