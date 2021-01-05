//
//  WidgetTitleView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-31.
//

import Lottie
import UIKit

class WidgetTitleView: ThemeableView {
    // MARK: Private Properties

    private let animationViewSize: CGFloat = 18.0
    private var lottieView: AnimationView?

    // MARK: UI Properties

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
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

    private var timerDuration: TimeInterval?
    private var interactionTimer: Timer?

    // MARK: Initialization

    override init() {
        super.init()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    // MARK: Private Functions - View Setup

    private func configure() {
        configureAnimationView()
        configureTitleLabel()
        configureLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(didMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func didMoveToForeground() {
        // Restart the timer animation from continuous time since background
        // We need to do this because when Lottie goes into background it pauses the animation
        if
            let interactionTimer = interactionTimer,
            let lottieView = lottieView,
            let lottieAnimation = lottieView.animation,
            let duration = timerDuration
        {
            let timeRemaining = interactionTimer.fireDate.timeIntervalSince(Date())
            let timeScalar = lottieAnimation.duration / duration

            lottieView.currentTime = (duration - timeRemaining) * timeScalar
            lottieView.play()
        }
    }

    private func configureTitleLabel() {
        addSubview(titleLabel)
        titleLabel.textAlignment = .left
    }

    private func configureAnimationView() {
        addSubview(animationView)
    }

    func beginTimer(duration: Double, animationFilepath: String, completion: (() -> Void)? = nil) {
        timerDuration = duration
        interactionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
            completion?()
        })

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
            }
        }

        self.lottieView = lottieView
    }

    func showCloseButton() {
        animationView.addSubview(closeButton)
        closeButton.constraintsFill(to: animationView)
    }

    func beginTimer(duration: Double, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: completion)
    }

    private func configureLayout() {
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
    }
}
