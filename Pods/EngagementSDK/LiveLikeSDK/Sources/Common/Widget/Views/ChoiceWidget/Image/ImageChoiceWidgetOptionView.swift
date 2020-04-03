//
//  ImagePredictionOptionView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import UIKit

class ImageChoiceWidgetOptionView: ChoiceWidgetOptionButton {
    var onButtonPressed: ((ChoiceWidgetOptionButton) -> Void)?

    var id: String

    private var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.numberOfLines = 2
        label.textAlignment = .right
        return label
    }()

    private var optionImageView: GIFImageView = {
        let image = GIFImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.isUserInteractionEnabled = false
        image.contentMode = .scaleAspectFit
        return image
    }()

    lazy var gradientView: GradientView = {
        let gradientView = GradientView(orientation: .vertical)
        gradientView.isUserInteractionEnabled = false
        gradientView.livelike_startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        gradientView.livelike_endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        return gradientView
    }()

    private var percentageView: ProgressBarAndLabelView = {
        let percentageView = ProgressBarAndLabelView()
        percentageView.translatesAutoresizingMaskIntoConstraints = false
        percentageView.isUserInteractionEnabled = false
        return percentageView
    }()

    init(id: String) {
        self.id = id
        super.init(frame: .zero)
        configure()
        addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    func setImage(_ imageURL: URL) {
        optionImageView.setImage(key: imageURL.absoluteString)
    }

    func setBorderColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
    }

    @objc private func buttonPressed() {
        onButtonPressed?(self)
    }

    func setProgress(_ percent: CGFloat) {
        percentageView.setProgress(percent: percent)
    }

    func setText(_ text: String, theme: Theme) {
        textLabel.setWidgetPrimaryText(text, theme: theme, alignment: .right)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientView.frame = CGRect(x: 0, y: bounds.maxY - 45, width: bounds.width, height: 45)
    }

    private func configure() {
        clipsToBounds = true

        configurePercentageView()
        configureImage()
        addSubview(gradientView)
        configureLabel()
    }

    private func configureImage() {
        addSubview(optionImageView)
        NSLayoutConstraint.activate([
            optionImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            optionImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -6),
            optionImageView.widthAnchor.constraint(equalToConstant: 80),
            optionImageView.heightAnchor.constraint(equalToConstant: 80)

        ])
    }

    private func configureLabel() {
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
        ])
    }

    private func configurePercentageView() {
        addSubview(percentageView)
        NSLayoutConstraint.activate([
            percentageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            percentageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            percentageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            percentageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func setColors(_ colors: ChoiceWidgetOptionColors) {
        layer.borderColor = colors.borderColor.cgColor
        percentageView.setBarColors(startColor: colors.barGradientLeft,
                                    endColor: colors.barGradientRight)
    }

    func customize(_ theme: Theme) {
        backgroundColor = theme.widgetBodyColor
        layer.borderColor = UIColor.clear.cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = theme.widgetCornerRadius
        percentageView.setLabelTextColor(theme.widgetFontTertiaryColor)
        percentageView.setLabelFont(theme.fontTertiary)
        percentageView.setBarCornerRadius(theme.widgetCornerRadius)
        gradientView.livelike_startColor = theme.widgetBodyColor.withAlphaComponent(0)
        gradientView.livelike_endColor = theme.widgetBodyColor.withAlphaComponent(0.6)
    }
}
