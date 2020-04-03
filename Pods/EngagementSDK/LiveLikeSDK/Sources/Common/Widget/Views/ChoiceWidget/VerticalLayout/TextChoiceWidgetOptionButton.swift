//
//  TextPredictionOptionView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-31.
//

import UIKit

class TextChoiceWidgetOptionButton: ChoiceWidgetOptionButton {
    // MARK: Internal

    var id: String
    var onButtonPressed: ((ChoiceWidgetOptionButton) -> Void)?

    // MARK: Private Properties

    private var percentageViewPadding: CGFloat = 8
    private var theme: Theme = Theme()

    private var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        return label
    }()

    private var percentageView: ProgressBarAndLabelView = {
        let percentageView = ProgressBarAndLabelView()
        percentageView.isUserInteractionEnabled = false
        return percentageView
    }()

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
                layer.borderWidth = theme.selectedOptionBorderWidth
                textLabel.textColor = theme.selectedOptionTextColor
                layer.cornerRadius = theme.widgetCornerRadius
            } else {
                layer.borderWidth = theme.unselectedOptionBorderWidth
                textLabel.textColor = theme.widgetFontPrimaryColor
                layer.cornerRadius = theme.unselectedOptionCornerRadius
            }
        }
    }

    func setImage(_ imageURL: URL) {
        // not implemented
    }

    func setBorderColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
    }

    func setProgress(_ percent: CGFloat) {
        percentageView.setProgress(percent: percent)
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
        configurePercentageView()
        configureTitleLabel()
        layer.borderWidth = 2.0
    }

    private func configureTitleLabel() {
        addSubview(textLabel)

        textLabel.textAlignment = .left

        let constraints = [
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -55),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func configurePercentageView() {
        addSubview(percentageView)
        percentageView.translatesAutoresizingMaskIntoConstraints = false

        let percentageViewBottomAnchor = percentageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        percentageViewBottomAnchor.priority = .defaultLow

        let constraints = [
            percentageView.topAnchor.constraint(equalTo: topAnchor, constant: percentageViewPadding),
            percentageView.heightAnchor.constraint(lessThanOrEqualToConstant: 28),
            percentageViewBottomAnchor,
            percentageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -percentageViewPadding),
            percentageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: percentageViewPadding)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setColors(_ colors: ChoiceWidgetOptionColors) {
        layer.borderColor = colors.borderColor.cgColor
        percentageView.setBarColors(startColor: colors.barGradientLeft,
                                    endColor: colors.barGradientRight)
    }

    func customize(_ theme: Theme) {
        self.theme = theme

        layer.cornerRadius = theme.unselectedOptionCornerRadius
        layer.borderColor = theme.neutralOptionColors.borderColor.cgColor
        layer.borderWidth = theme.unselectedOptionBorderWidth
        backgroundColor = .clear

        percentageView.setLabelTextColor(theme.widgetFontTertiaryColor)
        percentageView.setLabelFont(theme.fontTertiary)
        percentageView.setBarCornerRadius(theme.widgetCornerRadius)
    }
}
