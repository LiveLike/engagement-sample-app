//
//  TextPredictionOptionView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-31.
//

import UIKit

class TextChoiceWidgetOptionButton: ThemeableView, ChoiceWidgetOption {

    weak var delegate: ChoiceWidgetOptionDelegate?

    var optionThemeStyle: OptionThemeStyle = .unselected

    var barCornerRadii: Theme.CornerRadii = .zero {
        didSet {
            self.percentageView.progressBar.roundCorners(cornerRadii: barCornerRadii)
        }
    }
    
    var descriptionFont: UIFont? {
        get {
            return textLabel.font
        }
        set {
            textLabel.font = newValue
        }
    }
    
    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }
    
    var descriptionTextColor: UIColor? {
        get {
            return textLabel.textColor
        }
        set {
            textLabel.textColor = newValue
        }
    }
    
    var percentageFont: UIFont? {
        get {
            return percentageView.progressLabel.font
        }
        set {
            percentageView.progressLabel.font = newValue
        }
    }
    
    var percentageTextColor: UIColor? {
        get {
            return percentageView.progressLabel.textColor
        }
        set {
            percentageView.progressLabel.textColor = newValue
        }
    }
    
    var barBackground: Theme.Background? {
        didSet {
            switch barBackground {
            case .fill(let color):
                percentageView.progressBar.setColors(startColor: color, endColor: color)
            case .gradient(let gradient):
                guard
                    let startColor = gradient.colors[safe: 0],
                    let endColor = gradient.colors[safe: 1]
                else {
                    log.error("Failed to find two colors for the gradient")
                    return
                }
                
                percentageView.progressBar.setColors(startColor: startColor, endColor: endColor)
            default:
                break
            }
        }
    }
    
    var image: UIImage?
    
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

    required init(id: String) {
        self.id = id
        super.init()
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

    func setImage(_ imageURL: URL) {
        // not implemented
    }

    func setProgress(_ percent: CGFloat) {
        percentageView.setProgress(percent: percent)
    }

    @objc private func buttonPressed() {
        delegate?.wasSelected(self)
    }

    // MARK: Private Functions - View Setup

    private func configure() {
        configurePercentageView()
        configureTitleLabel()
        clipsToBounds = true
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
}
