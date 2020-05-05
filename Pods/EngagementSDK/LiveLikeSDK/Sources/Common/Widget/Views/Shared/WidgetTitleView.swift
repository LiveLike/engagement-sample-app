//
//  WidgetTitleView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-31.
//

import Lottie
import UIKit

class WidgetTitleView: UIView {
    // MARK: Private Properties

    private let animationViewSize: CGFloat = 18.0
    private var lottieView: AnimationView?
    private var timeAnimationStarted: TimeInterval?

    // MARK: UI Properties

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    lazy var gradientView: GradientView = {
        let gradientView = GradientView(orientation: .horizontal)
        return gradientView
    }()

    var closeButton: UIButton = {
        let image = UIImage(named: "widget_close", in: Bundle(for: WidgetTitleView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(image, for: .normal)
        return button
    }()

    private var titleLeadingConstraint: NSLayoutConstraint!
    private var titleTrailingConstraint: NSLayoutConstraint!
    private var titleTopConstraint: NSLayoutConstraint!
    private var titleBottomConstraint: NSLayoutConstraint!

    var titleMargins: UIEdgeInsets = .zero {
        didSet {
            titleLeadingConstraint.constant = titleMargins.left
            titleTrailingConstraint.constant = titleMargins.right
            titleTopConstraint.constant = titleMargins.top
            titleBottomConstraint.constant = titleMargins.bottom
        }
    }

    private lazy var animationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Initialization

    init() {
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    // MARK: Private Functions - View Setup

    private func configure() {
        configureGradientView()
        configureAnimationView()
        configureTitleLabel()
        configureLayout()
    }

    private func configureTitleLabel() {
        addSubview(titleLabel)
        titleLabel.textAlignment = .left
    }

    private func configureAnimationView() {
        addSubview(animationView)
    }

    func beginTimer(duration: Double, animationFilepath: String, completion: (() -> Void)? = nil) {
        let lottieView = AnimationView(filePath: animationFilepath)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.contentMode = .scaleAspectFit
        if let animationDuration = lottieView.animation?.duration, duration > 0 {
            lottieView.animationSpeed = CGFloat(animationDuration / duration)
        }

        animationView.addSubview(lottieView)

        // animationViewSize
        let constraints = [
            animationView.centerXAnchor.constraint(equalTo: lottieView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: lottieView.centerYAnchor),
            lottieView.heightAnchor.constraint(equalToConstant: animationViewSize),
            lottieView.widthAnchor.constraint(equalToConstant: animationViewSize)
        ]

        NSLayoutConstraint.activate(constraints)

        lottieView.play { finished in
            if finished {
                lottieView.isHidden = true
                completion?()
            }
        }

        timeAnimationStarted = Date().timeIntervalSince1970
    }

    func showCloseButton() {
        animationView.addSubview(closeButton)
        closeButton.constraintsFill(to: animationView)
    }

    func beginTimer(duration: Double, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: completion)
    }

    private func configureGradientView() {
        addSubview(gradientView)
    }

    private func configureLayout() {
        // Gradient View
        gradientView.constraintsFill(to: self)

        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor)
        titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        titleTrailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: animationView.leadingAnchor)

        // Title Label
        let constraints: [NSLayoutConstraint] = [

            titleLeadingConstraint,
            titleTrailingConstraint,
            titleTopConstraint,
            titleBottomConstraint,

            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 32),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Theme

extension WidgetTitleView {
    func customizeTitle(font: UIFont, textColor: UIColor, gradientStart: UIColor, gradientEnd: UIColor) {
        titleLabel.textColor = textColor
        titleLabel.font = font
        gradientView.livelike_startColor = gradientStart
        gradientView.livelike_endColor = gradientEnd
    }
}
