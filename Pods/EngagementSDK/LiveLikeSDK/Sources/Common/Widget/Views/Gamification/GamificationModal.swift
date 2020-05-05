//
//  PointsTutorialView.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 7/29/19.
//

import Lottie
import UIKit

class GamificationModal: PassthroughView {
    // the margin amount from leading & trailing
    private let contentViewSideMargins: CGFloat = 10.0

    private var autoLayoutConstraints: [NSLayoutConstraint] = Array()
    private var contentViewWidth: NSLayoutConstraint = NSLayoutConstraint()
    private var actionButtonHandler: (() -> Void)?
    private var actionButtonTitle: String?
    private var progressionMeterHeight: NSLayoutConstraint
    private var progressionMeterWidth: NSLayoutConstraint

    // MARK: - UI Elements

    private let contentView: UIView = {
        let contentView: UIView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.livelike_cornerRadius = 5.0
        return contentView
    }()

    private let titleLabel: UILabel = {
        let titleLabel: UILabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.layer.shadowColor = UIColor.white.cgColor
        titleLabel.layer.shadowRadius = 5
        titleLabel.layer.shadowOpacity = 1
        titleLabel.layer.shadowOffset = .zero
        titleLabel.layer.masksToBounds = false
        return titleLabel
    }()

    private let messageLabel: UILabel = {
        let messageLabel: UILabel = UILabel(frame: .zero)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        return messageLabel
    }()

    private let actionButton: UIButton = {
        let actionButton: UIButton = UIButton(frame: .zero)
        actionButton.livelike_cornerRadius = 3.0
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return actionButton
    }()

    private let progressionMeter: UIView
    private let graphicView: UIView

    // MARK: - UI Set Up

    private func setUpLayout() {
        contentViewWidth = contentView.widthAnchor.constraint(equalTo: widthAnchor)

        autoLayoutConstraints = [
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0),
            contentViewWidth,
            contentView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50.0),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10.0),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            graphicView.centerYAnchor.constraint(equalTo: contentView.topAnchor, constant: 0.0),
            graphicView.widthAnchor.constraint(equalToConstant: 80.0),
            graphicView.heightAnchor.constraint(equalToConstant: 80.0),
            graphicView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 120.0),
            actionButton.heightAnchor.constraint(equalToConstant: 32.0),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.centerYAnchor.constraint(equalTo: contentView.bottomAnchor),
            progressionMeter.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 15.0),
            progressionMeter.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressionMeterHeight,
            progressionMeterWidth,
            progressionMeter.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0)
        ]
        NSLayoutConstraint.activate(autoLayoutConstraints)
    }

    private func setUpViews() {
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(progressionMeter)
        addSubview(graphicView)
        addSubview(actionButton)
    }

    private func applyTheme(theme: Theme) {
        titleLabel.font = theme.popupTitleFont
        titleLabel.textColor = theme.popupTitleColor
        messageLabel.font = theme.popupMessageFont
        messageLabel.textColor = theme.popupMessageColor
        contentView.backgroundColor = theme.widgetBodyColor
        actionButton.backgroundColor = theme.popupActionButtonBg
        if let actionButtonTitle = actionButtonTitle {
            actionButton.setTitle(actionButtonTitle, for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.titleLabel?.font = theme.fontPrimary
        }
    }

    @objc private func actionButtonTapped() {
        if let actionButtonHandler = actionButtonHandler {
            actionButtonHandler()
        }
    }

    // MARK: - INIT

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    /// Main init method that creates UIView object
    ///
    /// - Parameters:
    ///   - title: headline of the modal
    ///   - message: content message of the modal
    ///   - sourceView: the view into which the modal will be placed in
    ///   - progressionMeter: progression meter view
    ///   - theme: theme
    ///   - actionButtonTitle: optional - text of the action button
    ///   - actionButtonHandler: optional - completion handler for the action button
    private init(title: String?,
                 message: String,
                 progressionMeter: UIView?,
                 theme: Theme,
                 actionButtonTitle: String?,
                 actionButtonHandler: (() -> Void)?,
                 graphicView: UIView) {
        if let progressMeter = progressionMeter {
            self.progressionMeter = progressMeter
            progressionMeterHeight = progressMeter.heightAnchor.constraint(equalToConstant: 30)
            progressionMeterWidth = progressMeter.widthAnchor.constraint(equalToConstant: 100)
        } else {
            self.progressionMeter = UIView()
            progressionMeterHeight = self.progressionMeter.heightAnchor.constraint(equalToConstant: 0)
            progressionMeterWidth = self.progressionMeter.widthAnchor.constraint(equalToConstant: 0)
        }

        self.progressionMeter.translatesAutoresizingMaskIntoConstraints = false
        self.graphicView = graphicView

        super.init(frame: .zero)

        titleLabel.text = title
        messageLabel.text = message
        self.actionButtonHandler = actionButtonHandler
        self.actionButtonTitle = actionButtonTitle

        if actionButtonTitle == nil {
            actionButton.isHidden = true
        }

        setUpViews()
        setUpLayout()
        applyTheme(theme: theme)
    }

    convenience init(title: String?,
                     message: String,
                     progressionMeter: UIView?,
                     theme: Theme,
                     graphicImage: UIImage?,
                     actionButtonTitle: String?,
                     actionButtonHandler: (() -> Void)?) {
        let imageView = UIImageView(image: graphicImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        self.init(title: title,
                  message: message,
                  progressionMeter: progressionMeter,
                  theme: theme,
                  actionButtonTitle: actionButtonTitle,
                  actionButtonHandler: actionButtonHandler,
                  graphicView: imageView)
    }

    convenience init(title: String?,
                     message: String,
                     progressionMeter: UIView?,
                     theme: Theme,
                     graphicLottieAnimation: String) {
        
        let lottieContainer = UIView()
        lottieContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let lottieView = AnimationView(name: graphicLottieAnimation, bundle: Bundle(for: GamificationModal.self))
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopMode = .loop
        lottieView.play()
        
        lottieContainer.addSubview(lottieView)
        lottieView.constraintsFill(to: lottieContainer, offset: 15)

        self.init(title: title,
                  message: message,
                  progressionMeter: progressionMeter,
                  theme: theme,
                  actionButtonTitle: nil,
                  actionButtonHandler: nil,
                  graphicView: lottieContainer)
    }
}

// MARK: - Animations

extension GamificationModal {
    func animateGraphic() {
        graphicView.rotate360Degrees(duration: 0.3, completionDelegate: nil)
    }

    func playBadgeCollectAnimation() -> Promise<Bool> {
        return firstly {
            UIView.animate(duration: 0.1) {
                self.contentView.alpha = 0
                self.actionButton.alpha = 0
            }
        }.then { _ in
            UIView.animatePromise(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 1, options: .curveEaseInOut) {
                let newTransform = CGAffineTransform(translationX: 0, y: self.contentView.bounds.height / 2).scaledBy(x: 1.6, y: 1.6)
                self.graphicView.transform = newTransform
            }
        }.then { _ in
            UIView.animate(duration: 0.4, delay: 0.5, options: []) {
                self.graphicView.alpha = 0
            }
        }
    }
}
