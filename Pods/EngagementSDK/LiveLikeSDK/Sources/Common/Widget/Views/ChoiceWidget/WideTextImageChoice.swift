//
//  WideTextImageChoice.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/18/19.
//

import UIKit

class WideTextImageChoice: ThemeableView, ChoiceWidgetOption {
    
    weak var delegate: ChoiceWidgetOptionDelegate?
    
    var optionThemeStyle: OptionThemeStyle = .unselected

    var barCornerRadii: Theme.CornerRadii = .zero {
        didSet {
            self.progressBar.roundCorners(cornerRadii: barCornerRadii)
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
            return progressLabel.font
        }
        set {
            progressLabel.font = newValue
        }
    }
    
    var percentageTextColor: UIColor? {
        get {
            return progressLabel.textColor
        }
        set {
            progressLabel.textColor = newValue
        }
    }
    
    var barBackground: Theme.Background? {
        didSet {
            guard let barBackground = barBackground else { return }
            progressBar.background = barBackground
        }
    }
    
    var image: UIImage? {
        get {
            return optionImageView.image
        } set {
            optionImageView.image = newValue
        }
    }
    
    // MARK: Internal

    var id: String

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
        optionImageView.setImage(url: imageURL)
    }

    func setBorderColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
    }

    func setProgress(_ percent: CGFloat) {
        progressLabel.setProgress(percent)
        progressBar.setProgress(percent)
        progressLabel.isHidden = false
    }

    @objc private func buttonPressed() {
        delegate?.wasSelected(self)
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
}
