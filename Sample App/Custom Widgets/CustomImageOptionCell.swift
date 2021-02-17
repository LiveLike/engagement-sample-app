//
//  CustomImageQuizChoiceCell.swift
//  LiveLikeTestApp
//
//  Created by Mike Moloksher on 1/7/21.
//

import EngagementSDK
import UIKit

class CustomImageOptionCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let choiceMainLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont(name: "HelveticaNeue-Regular", size: 14.0)
        return label
    }()

    private let choiceSecondaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 16.0)
        label.isHidden = true
        return label
    }()

    private var progressView: UIView = {
        var view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ProgressColors.gray.color
        view.isHidden = true
        return view
    }()

    private var mainLabelConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var progressViewWidth: NSLayoutConstraint = NSLayoutConstraint()
    var choiceID: String = ""

    enum ProgressColors {
        case gray
        case green
        case red

        var color: UIColor {
            switch self {
            case .gray:
                return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
            case .green:
                return UIColor(red: 0/255, green: 255/255, blue: 120/255, alpha: 1.0)
            case .red:
                return UIColor(red: 255/255, green: 60/255, blue: 60/255, alpha: 1.0)
            }
        }
    }

    enum CustomImageQuizCellMode {
        case unselected
        case selected
        case showResults
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.borderWidth = 1.0
        contentView.layer.cornerRadius = 4.0

        contentView.addSubview(imageView)
        contentView.addSubview(choiceMainLabel)
        contentView.addSubview(choiceSecondaryLabel)
        addSubview(progressView)

        contentView.clipsToBounds = true

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -2),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1.0),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1),

            choiceMainLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            choiceMainLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -10.0),
            choiceMainLabel.heightAnchor.constraint(equalToConstant: 30),

            choiceSecondaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            choiceSecondaryLabel.topAnchor.constraint(equalTo: choiceMainLabel.bottomAnchor, constant: 3.0),

            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4.0),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        mainLabelConstraint = choiceMainLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        mainLabelConstraint.isActive = true
        progressViewWidth = progressView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
        progressViewWidth.isActive = true

        setMode(mode: .unselected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    /// Configure the way the cell looks
    func configure(choice: QuizWidgetModel.Choice) {
        do {
            guard let imageURL = choice.imageURL else { return }
            let data = try Data(contentsOf: imageURL)
            imageView.image = UIImage(data: data)
        } catch {
            print(error)
        }

        choiceID = choice.id
        choiceMainLabel.text = choice.text
    }

    func configure(option: PollWidgetModel.Option) {
        do {
            guard let imageURL = option.imageURL else { return }
            let data = try Data(contentsOf: imageURL)
            imageView.image = UIImage(data: data)
        } catch {
            print(error)
        }

        choiceID = option.id
        choiceMainLabel.text = option.text
    }

    func configure(option: PredictionWidgetModel.Option) {
        do {
            guard let imageURL = option.imageURL else { return }
            let data = try Data(contentsOf: imageURL)
            imageView.image = UIImage(data: data)
        } catch {
            print(error)
        }

        choiceID = option.id
        choiceMainLabel.text = option.text
    }

    func configure(option: PredictionFollowUpWidgetModel.Option) {
        do {
            guard let imageURL = option.imageURL else { return }
            let data = try Data(contentsOf: imageURL)
            imageView.image = UIImage(data: data)
        } catch {
            print(error)
        }

        choiceID = option.id
        choiceMainLabel.text = option.text
    }

    /// Change the progress bar of the cell
    func setProgressAndColor(progress: CGFloat, color: UIColor = WidgetViewHelpers.colors.gray) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressViewWidth.isActive = false
            self.progressView.backgroundColor = color
            self.progressViewWidth = self.progressView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: progress)
            self.progressViewWidth.isActive = true
            self.choiceSecondaryLabel.text = "\(Int(progress * 100))%"
            self.progressView.layoutIfNeeded()
            self.progressView.setNeedsLayout()
        }
    }

    func setProgress(progress: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressViewWidth.isActive = false
            self.progressViewWidth = self.progressView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: progress)
            self.progressViewWidth.isActive = true
            self.choiceSecondaryLabel.text = "\(Int(progress * 100))%"
            self.progressView.layoutIfNeeded()
            self.progressView.setNeedsLayout()
        }
    }

    /// Set the mode of the cell to change it's UI
    func setMode(mode: CustomImageQuizCellMode) {
        switch mode {
        case .unselected:
            contentView.backgroundColor = .white
            contentView.layer.borderColor = ProgressColors.gray.color.cgColor
            choiceMainLabel.textColor = .black
            choiceSecondaryLabel.textColor = .black
        case .selected:
            contentView.backgroundColor = .black
            contentView.layer.borderColor = UIColor.black.cgColor
            choiceMainLabel.textColor = .white
            choiceSecondaryLabel.textColor = .white
        case .showResults:
            mainLabelConstraint.constant = -10.0
            choiceSecondaryLabel.isHidden = false
            progressView.isHidden = false
        }
    }
}
