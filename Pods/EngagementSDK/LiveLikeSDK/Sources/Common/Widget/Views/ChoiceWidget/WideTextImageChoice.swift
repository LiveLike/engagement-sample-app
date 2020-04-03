//
//  WideTextImageChoice.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/18/19.
//

import UIKit

class WideTextImageChoice: ChoiceWidgetOptionButton {
    // MARK: Internal

    var id: String
    var onButtonPressed: ((ChoiceWidgetOptionButton) -> Void)?

    // MARK: Private Properties

    private var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        return label
    }()

    private var progressBar: ProgressBar = {
        let percentageView = ProgressBar()
        percentageView.translatesAutoresizingMaskIntoConstraints = false
        percentageView.isUserInteractionEnabled = false
        return percentageView
    }()

    private var optionImageView: UIImageViewAligned = {
        let image = UIImageViewAligned()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.isUserInteractionEnabled = false
        image.contentMode = .scaleAspectFit
        image.alignment = .right
        return image
    }()

    private var progressLabel: ProgressLabel = {
        let progressLabel = ProgressLabel()
        progressLabel.text = "0"
        progressLabel.isHidden = true
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        return progressLabel
    }()

    private var theme: Theme = Theme()

    // MARK: Initialization

    init(id: String) {
        self.id = id
        super.init(frame: .zero)
        configure()
        addGestureRecognizer({
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(buttonPressed))
            tapGestureRecognizer.numberOfTapsRequired = 1
            return tapGestureRecognizer
        }())
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.cornerRadius = theme.widgetCornerRadius
                layer.borderWidth = theme.selectedOptionBorderWidth
                textLabel.textColor = theme.selectedOptionTextColor
            } else {
                layer.cornerRadius = theme.unselectedOptionCornerRadius
                layer.borderWidth = theme.unselectedOptionBorderWidth
                textLabel.textColor = theme.widgetFontPrimaryColor
            }
        }
    }

    func setImage(_ imageURL: URL) {
        optionImageView.setImage(key: imageURL.absoluteString)
    }

    func setBorderColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
    }

    func setProgress(_ percent: CGFloat) {
        progressLabel.setProgress(percent)
        progressBar.setProgress(percent)
        progressLabel.isHidden = false
    }

    func setText(_ text: String, theme: Theme) {
        let optionText = theme.uppercaseOptionText ? text.uppercased() : text
        textLabel.setWidgetPrimaryText(optionText, theme: theme)
    }

    @objc private func buttonPressed() {
        onButtonPressed?(self)
    }

    // MARK: Private Functions - View Setup

    private func configure() {
        clipsToBounds = true
        textLabel.textAlignment = .left

        addSubview(optionImageView)
        addSubview(progressBar)
        addSubview(progressLabel)
        addSubview(textLabel)

        let textBottomConstraint = textLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        textBottomConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            textLabel.trailingAnchor.constraint(equalTo: optionImageView.leadingAnchor, constant: 0),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            optionImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            optionImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            optionImageView.heightAnchor.constraint(equalToConstant: 63),
            optionImageView.widthAnchor.constraint(equalToConstant: 90),

            progressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 8),
            progressLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            progressLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),

            progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            progressBar.heightAnchor.constraint(equalToConstant: 22),
            progressBar.trailingAnchor.constraint(equalTo: optionImageView.leadingAnchor, constant: -8),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        ])
    }

    func setColors(_ colors: ChoiceWidgetOptionColors) {
        layer.borderColor = colors.borderColor.cgColor
        progressBar.setColors(startColor: colors.barGradientLeft,
                              endColor: colors.barGradientRight)
    }

    func customize(_ theme: Theme) {
        self.theme = theme
        
        if isSelected {
            layer.cornerRadius = theme.widgetCornerRadius
        } else {
            layer.cornerRadius = theme.unselectedOptionCornerRadius
        }
        layer.borderWidth = theme.unselectedOptionBorderWidth
        layer.borderColor = theme.neutralOptionColors.borderColor.cgColor
        backgroundColor = .clear

        progressLabel.textColor = theme.widgetFontTertiaryColor
        progressLabel.font = theme.fontTertiary
        progressBar.gradientView.livelike_cornerRadius = theme.widgetCornerRadius / 2
    }
}
