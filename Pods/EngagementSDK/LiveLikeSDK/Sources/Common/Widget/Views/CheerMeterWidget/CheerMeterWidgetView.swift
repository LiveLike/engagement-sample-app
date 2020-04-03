//
//  CheerMeterWidgetView.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/10/19.
//

import Lottie
import UIKit

class CheerMeterWidgetView: WidgetView {
    internal let coreWidgetView: CoreWidgetView

    private let titleLabel: UILabel
    private let timerView: LOTAnimationView
    private let titleConstraints: HeaderViews.TitleConstraints
    private let leftChoiceImageView: UIImageView
    private let rightChoiceImageView: UIImageView
    private let versusSeparatorView: LOTAnimationView

    private let leftChoiceSelectionConstraints: [NSLayoutConstraint]
    private let leftChoiceCenterConstraints: [NSLayoutConstraint]
    private let rightChoiceSelectionConstraints: [NSLayoutConstraint]
    private let rightChoiceCenterConstraints: [NSLayoutConstraint]
    private let versusSeparatorViewCenterXConstraint: NSLayoutConstraint
    private let scoreLabel: UILabel
    private let scoreTitleLabel: UILabel
    private let tutorialContainer: UIView
    private let tutorialInstructionLabel: UILabel
    private let countdownLabel: UILabel
    private let handImageView: UIImageView
    private let pulseCircleView: CircleShapeView
    private let powerBar: CheerMeterPowerBar

    private let defaultChoiceTransform: CGAffineTransform = .identity
    private let zoomedChoiceTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.3, y: 1.3)
    private let shrinkedChoiceTransform: CGAffineTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)

    private var choiceImageViewInCenter: UIImageView?

    private var theme: Theme = Theme()
    weak var delegate: CheerMeterWidgetViewDelegate?

    init() {
        let properties = constructViews()

        coreWidgetView = properties.coreWidgetView
        titleLabel = properties.headerViews.titleLabel
        timerView = properties.headerViews.timerView
        titleConstraints = properties.headerViews.titleConstraints
        leftChoiceImageView = properties.interactionViews.leftChoiceImageView
        rightChoiceImageView = properties.interactionViews.rightChoiceImageView
        versusSeparatorView = properties.interactionViews.versusSeparatorView
        leftChoiceSelectionConstraints = properties.interactionViews.leftChoiceSelectionConstraints
        leftChoiceCenterConstraints = properties.interactionViews.leftChoiceCenterConstraints
        rightChoiceSelectionConstraints = properties.interactionViews.rightChoiceSelectionConstraints
        rightChoiceCenterConstraints = properties.interactionViews.rightChoiceCenterConstraints
        versusSeparatorViewCenterXConstraint = properties.interactionViews.versusSeparatorViewCenterXConstraint
        scoreLabel = properties.interactionViews.scoreLabel
        scoreTitleLabel = properties.interactionViews.scoreTitleLabel
        tutorialContainer = properties.tutorialViews.container
        tutorialInstructionLabel = properties.tutorialViews.instructionLabel
        countdownLabel = properties.tutorialViews.countdownLabel
        handImageView = properties.tutorialViews.handImageView
        pulseCircleView = properties.tutorialViews.pulseCircleView
        powerBar = properties.meter

        super.init(frame: .zero)
        addSubview(coreWidgetView)

        configureSelectionGestures()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSelectionGestures() {
        let leftChoiceTapGesture = UITapGestureRecognizer(target: self, action: #selector(leftSelectionSelected))
        leftChoiceTapGesture.numberOfTapsRequired = 1
        leftChoiceImageView.isUserInteractionEnabled = true
        leftChoiceImageView.addGestureRecognizer(leftChoiceTapGesture)

        let rightChoiceTapGesture = UITapGestureRecognizer(target: self, action: #selector(rightSelectionSelected))
        rightChoiceTapGesture.numberOfTapsRequired = 1
        rightChoiceImageView.isUserInteractionEnabled = true
        rightChoiceImageView.addGestureRecognizer(rightChoiceTapGesture)
    }

    @objc private func leftSelectionSelected() {
        delegate?.optionSelected(button: .leftChoice)
    }

    @objc private func rightSelectionSelected() {
        delegate?.optionSelected(button: .rightChoice)
    }
}

// MARK: - Properties

internal extension CheerMeterWidgetView {
    var titleText: String {
        get { return titleLabel.text ?? "" }
        set {
            let newValue = theme.uppercaseTitleText ? newValue.uppercased() : newValue
            applyText(newValue, to: .title)
        }
    }

    var leftChoiceText: String {
        get { return powerBar.leftChoiceText }
        set { powerBar.leftChoiceText = newValue }
    }

    var rightChoiceText: String {
        get { return powerBar.rightChoiceText }
        set { powerBar.rightChoiceText = newValue }
    }

    func applyTheme(_ theme: Theme) {
        guard self.theme != theme else {
            return
        }

        self.theme = theme

        coreWidgetView.headerView?.backgroundColor = theme.cheerMeter.titleBackgroundColor

        titleConstraints.topConstraint.constant = theme.cheerMeter.titleMargins.top
        titleConstraints.bottomConstraint.constant = theme.cheerMeter.titleMargins.bottom
        titleConstraints.leadingConstraint.constant = theme.cheerMeter.titleMargins.left
        titleConstraints.trailingConstraint.constant = theme.cheerMeter.titleMargins.right

        coreWidgetView.baseView.clipsToBounds = theme.widgetCornerRadius > 0
        coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        coreWidgetView.contentView?.backgroundColor = theme.widgetBodyColor

        applyText(titleText, to: .title)
        applyText(scoreTitle, to: .scoreTitle)
        applyText(instructionText, to: .instruction)

        countdownLabel.font = theme.cheerMeter.scoreAndCountdownFont
        countdownLabel.textColor = theme.cheerMeter.scoreAndCountdownTextColor
        scoreLabel.font = theme.cheerMeter.scoreAndCountdownFont
        scoreLabel.textColor = theme.cheerMeter.scoreAndCountdownTextColor

        powerBar.applyTheme(theme)
    }

    var timerDuration: CGFloat {
        get { return timerView.animationDuration / timerView.animationSpeed }
        set { timerView.animationSpeed = timerView.animationDuration / newValue }
    }

    func playTimerAnimation(completion: LOTAnimationCompletionBlock? = nil) {
        timerView.stop()
        timerView.play(completion: completion)
    }

    var leftChoiceImage: UIImage? {
        get { return leftChoiceImageView.image }
        set { leftChoiceImageView.image = newValue }
    }

    var rightChoiceImage: UIImage? {
        get { return rightChoiceImageView.image }
        set { rightChoiceImageView.image = newValue }
    }

    func playVersusAnimation(completion: LOTAnimationCompletionBlock? = nil) {
        versusSeparatorView.play(completion: completion)
    }

    var score: String {
        get { return scoreLabel.text ?? "" }
        set { scoreLabel.text = newValue }
    }

    var scoreTitle: String {
        get { return scoreTitleLabel.text ?? "" }
        set { applyText(newValue, to: .scoreTitle) }
    }

    var leftChoiceScore: Int {
        get { return powerBar.leftScore }
        set { powerBar.leftScore = newValue }
    }

    var rightChoiceScore: Int {
        get { return powerBar.rightScore }
        set { powerBar.rightScore = newValue }
    }

    var instructionText: String {
        get { return tutorialInstructionLabel.text ?? "" }
        set { applyText(newValue, to: .instruction) }
    }

    func setCircleFeedbackProperties(fillColor: UIColor, strokeColor: UIColor) {
        pulseCircleView.fillColor = fillColor.cgColor
        pulseCircleView.strokeColor = strokeColor.cgColor
    }

    func showScores() {
        scoreLabel.isHidden = false
        scoreTitleLabel.isHidden = false
        powerBar.shouldUpdateWidths = true
    }
}

protocol CheerMeterWidgetViewDelegate: AnyObject {
    func optionSelected(button: CheerMeterWidgetViewButtons)
}

enum CheerMeterWidgetViewButtons {
    case leftChoice
    case rightChoice
}

// MARK: - Animations

extension CheerMeterWidgetView {
    func playTapGameOverAnimation(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.coreWidgetView.alpha = 0.2
            self.choiceImageViewInCenter?.alpha = 0
        }, completion: { complete in
            if complete {
                completion()
            }
        })
    }

    func animateLeftSelectionCenter(completion: @escaping () -> Void) {
        choiceImageViewInCenter = leftChoiceImageView
        rightChoiceImageView.isHidden = true
        animateChoiceImageViewToCenter(choiceImageView: leftChoiceImageView,
                                       sideLayoutConstraints: leftChoiceSelectionConstraints,
                                       centerLayoutConstraints: leftChoiceCenterConstraints,
                                       completion: completion)
    }

    func animateRightSelectionCenter(completion: @escaping () -> Void) {
        choiceImageViewInCenter = rightChoiceImageView
        leftChoiceImageView.isHidden = true
        animateChoiceImageViewToCenter(choiceImageView: rightChoiceImageView,
                                       sideLayoutConstraints: rightChoiceSelectionConstraints,
                                       centerLayoutConstraints: rightChoiceCenterConstraints,
                                       completion: completion)
    }

    func playScoreAnimation() {
        pulseCircleView.pulse(duration: 0.2, sizeMultiplier: 1.3)
        playCenterImageViewRotationFeedbackAnimation()
    }

    func playTutorialAnimation(duration: TimeInterval, completion: @escaping () -> Void) {
        firstly {
            UIView.animate(duration: 0.1) {
                self.tutorialContainer.backgroundColor = self.theme.cheerMeter.tutorialBackgroundColor
            }
        }.then { (_) -> Promise<Bool> in
            UIView.animate(duration: 0.3) {
                self.tutorialInstructionLabel.alpha = 1
                self.handImageView.alpha = 1
                self.pulseCircleView.alpha = 1
            }
        }.then { (_) -> Promise<Bool> in
            self.pulseCircleView.repeatingPulse(rate: 0.3, sizeMultiplier: 1.2)
            UIView.animate(withDuration: 0.3,
                           delay: 0.0,
                           options: [.autoreverse, .repeat],
                           animations: { self.handImageView.transform = self.shrinkedChoiceTransform },
                           completion: nil)
            return self.countdownAnimation(duration: duration)
        }.then { (_) -> Promise<Bool> in
            UIView.animate(duration: 0.3) {
                self.tutorialContainer.backgroundColor = .clear
                self.tutorialInstructionLabel.alpha = 0
                self.countdownLabel.alpha = 0
                self.handImageView.alpha = 0
                self.pulseCircleView.alpha = 0
            }
        }.then { (_) -> Promise<Bool> in
            UIView.animate(duration: 0.3) {
                self.tutorialContainer.backgroundColor = .clear
                self.tutorialInstructionLabel.alpha = 0
                self.countdownLabel.alpha = 0
                self.handImageView.alpha = 0
                self.pulseCircleView.alpha = 0
            }
        }.then { (_) -> Promise<Bool> in
            UIView.animate(duration: 0.3, delay: 0.1, options: []) {
                self.choiceImageViewInCenter?.transform = self.defaultChoiceTransform
            }
        }.then { _ in
            completion()
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func flashLeftPowerBar() {
        powerBar.flashLeft()
    }

    func flashRightPowerBar() {
        powerBar.flashRight()
    }
}

// MARK: Animation Helpers

private extension CheerMeterWidgetView {
    func countdownAnimation(duration: TimeInterval) -> Promise<Bool> {
        let promise = Promise<Bool>()
        let segmentDuration = duration / 4

        countdownLabel.text = "3"
        delay(segmentDuration) { [weak self] in
            self?.countdownLabel.text = "2"
            delay(segmentDuration) { [weak self] in
                self?.countdownLabel.text = "1"
                delay(segmentDuration) { [weak self] in
                    self?.countdownLabel.text = "GO!"
                    delay(segmentDuration) {
                        promise.fulfill(true)
                    }
                }
            }
        }
        return promise
    }

    func animateChoiceImageViewToCenter(choiceImageView: UIImageView,
                                        sideLayoutConstraints: [NSLayoutConstraint],
                                        centerLayoutConstraints: [NSLayoutConstraint],
                                        completion: @escaping () -> Void) {
        choiceImageView.layer.removeAllAnimations()

        versusSeparatorView.isHidden = true
        UIView.animate(withDuration: 0.2, animations: {
            choiceImageView.transform = self.zoomedChoiceTransform
        }, completion: { _ in
            NSLayoutConstraint.deactivate(sideLayoutConstraints)
            NSLayoutConstraint.activate(centerLayoutConstraints)

            UIView.animate(withDuration: 0.3, delay: 0.3, options: .allowUserInteraction, animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                completion()
            })
        })
    }

    func playCenterImageViewRotationFeedbackAnimation() {
        guard let choiceImageViewInCenter = choiceImageViewInCenter else { return }
        choiceImageViewInCenter.layer.removeAllAnimations()
        choiceImageViewInCenter.transform = .identity
        UIView.animate(withDuration: 0.1,
                       delay: 0.0,
                       options: [.autoreverse, .allowUserInteraction, .curveLinear],
                       animations: {
                           choiceImageViewInCenter.transform = CGAffineTransform(rotationAngle: degreesToRadian(30))
                       }, completion: { finished in
                           if finished {
                               choiceImageViewInCenter.transform = .identity
                           }
        })
    }
}

func degreesToRadian(_ degrees: CGFloat) -> CGFloat {
    return CGFloat(degrees * CGFloat.pi / 180)
}

// MARK: - Private Helpers

private extension CheerMeterWidgetView {
    enum Label {
        case title
        case scoreTitle
        case instruction

        var alignment: NSTextAlignment {
            switch self {
            case .title, .scoreTitle, .instruction: return .natural
            }
        }

        var category: Theme.TextCategory {
            switch self {
            case .title, .scoreTitle: return .secondary
            case .instruction: return .tertiary
            }
        }
    }

    func UILabel(for label: Label) -> UILabel {
        switch label {
        case .title: return titleLabel
        case .scoreTitle: return scoreTitleLabel
        case .instruction: return tutorialInstructionLabel
        }
    }

    func applyText(_ text: String, to label: Label) {
        let labelView = UILabel(for: label)
        labelView.setWidgetText(text, for: theme,
                                category: label.category,
                                alignment: label.alignment)
    }
}

// MARK: - View Construction

func constraintBased<View>(factory: () -> View) -> View where View: UIView {
    let view = factory()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

private struct ConstructedProperties {
    let coreWidgetView: CoreWidgetView
    let headerViews: HeaderViews
    let meter: CheerMeterPowerBar
    let interactionViews: InteractionViews
    let tutorialViews: TutorialViews
}

private func constructViews() -> ConstructedProperties {
    let coreWidgetView = constraintBased { CoreWidgetView() }

    let headerViews: HeaderViews = constructHeader()
    let (body, meter, interactionPanel, tutorialViews) = constructBody()

    coreWidgetView.headerView = headerViews.container
    coreWidgetView.contentView = body

    headerViews.container.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    coreWidgetView.heightAnchor.constraint(greaterThanOrEqualToConstant: 176.0).isActive = true

    return ConstructedProperties(coreWidgetView: coreWidgetView,
                                 headerViews: headerViews,
                                 meter: meter,
                                 interactionViews: interactionPanel,
                                 tutorialViews: tutorialViews)
}

private struct HeaderViews {
    struct TitleConstraints {
        var topConstraint: NSLayoutConstraint
        var bottomConstraint: NSLayoutConstraint
        var leadingConstraint: NSLayoutConstraint
        var trailingConstraint: NSLayoutConstraint
    }

    var container: UIView
    var titleLabel: UILabel
    var titleConstraints: TitleConstraints
    var timerView: LOTAnimationView
}

private func constructHeader() -> HeaderViews {
    let titleLabel = constraintBased { UILabel(frame: .zero) }
    titleLabel.numberOfLines = 0
    let timerView = constraintBased {
        LOTAnimationView(name: AnimationAssets.widgetTimer,
                         bundle: Bundle(for: CheerMeterWidgetView.self))
    }

    let container = constraintBased { UIView(frame: .zero) }
    container.addSubview(titleLabel)
    container.addSubview(timerView)

    let titleConstraints = HeaderViews.TitleConstraints(
        topConstraint: titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
        bottomConstraint: titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        leadingConstraint: titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        trailingConstraint: titleLabel.trailingAnchor.constraint(equalTo: timerView.leadingAnchor)
    )

    NSLayoutConstraint.activate([
        timerView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
        timerView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        timerView.heightAnchor.constraint(equalToConstant: 18),
        timerView.widthAnchor.constraint(equalToConstant: 18),

        titleConstraints.topConstraint,
        titleConstraints.bottomConstraint,
        titleConstraints.leadingConstraint,
        titleConstraints.trailingConstraint
    ])

    return HeaderViews(
        container: container,
        titleLabel: titleLabel,
        titleConstraints: titleConstraints,
        timerView: timerView
    )
}

private typealias BodyViews = (
    container: UIView,
    meter: CheerMeterPowerBar,
    interactionPanel: InteractionViews,
    tutorialViews: TutorialViews
)

private func constructBody() -> BodyViews {
    let meter = constraintBased { CheerMeterPowerBar() }
    let interactionPanel = constructInteractionViews()
    let tutorialViews = constructTutorialView()

    interactionPanel.container.addSubview(tutorialViews.container)
    tutorialViews.container.constraintsFill(to: interactionPanel.container)

    meter.heightAnchor.constraint(equalToConstant: 20).isActive = true
    interactionPanel.container.heightAnchor.constraint(equalToConstant: 120).isActive = true

    let bodyStack = constraintBased {
        UIStackView(arrangedSubviews: [meter, interactionPanel.container])
    }
    bodyStack.axis = .vertical
    bodyStack.alignment = .fill
    bodyStack.distribution = .fill

    let container = UIView(frame: .zero)
    container.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)

    container.addSubview(bodyStack)
    bodyStack.constraintsFill(to: container)

    return (container, meter, interactionPanel, tutorialViews)
}

private struct InteractionViews {
    let container: UIView
    let leftChoiceImageView: UIImageView
    let rightChoiceImageView: UIImageView
    let versusSeparatorView: LOTAnimationView
    let leftChoiceSelectionConstraints: [NSLayoutConstraint]
    let leftChoiceCenterConstraints: [NSLayoutConstraint]
    let rightChoiceSelectionConstraints: [NSLayoutConstraint]
    let rightChoiceCenterConstraints: [NSLayoutConstraint]
    let versusSeparatorViewCenterXConstraint: NSLayoutConstraint
    let scoreLabel: UILabel
    let scoreTitleLabel: UILabel
}

// swiftlint:disable function_body_length

private func constructInteractionViews() -> InteractionViews {
    let container = constraintBased { UIView(frame: .zero) }

    let leftChoiceImageView = constraintBased { UIImageView(frame: .zero) }
    let rightChoiceImageView = constraintBased { UIImageView(frame: .zero) }
    let versusSeparatorView = constraintBased {
        LOTAnimationView(name: "cheer-meter-versus",
                         bundle: Bundle(for: CheerMeterWidgetView.self))
    }
    let scoreLabel = constraintBased { UILabel(frame: .zero) }
    let scoreTitleLabel = constraintBased { UILabel(frame: .zero) }

    container.clipsToBounds = true
    scoreLabel.isHidden = true
    scoreLabel.text = "0"
    scoreTitleLabel.isHidden = true

    container.addSubview(leftChoiceImageView)
    container.addSubview(rightChoiceImageView)
    container.addSubview(versusSeparatorView)
    container.addSubview(scoreLabel)
    container.addSubview(scoreTitleLabel)

    leftChoiceImageView.contentMode = .scaleAspectFit
    rightChoiceImageView.contentMode = .scaleAspectFit

    let zoomed = CGAffineTransform(scaleX: 1.2, y: 1.2)
    rightChoiceImageView.transform = zoomed
    let animateImageViews = {
        leftChoiceImageView.transform = zoomed
        rightChoiceImageView.transform = .identity
    }

    UIView.animate(withDuration: 1.0,
                   delay: 0.0,
                   options: [.autoreverse, .repeat, .allowUserInteraction],
                   animations: animateImageViews,
                   completion: nil)

    let versusCenterXConstraint = NSLayoutConstraint(item: versusSeparatorView,
                                                     attribute: .centerX,
                                                     relatedBy: .equal,
                                                     toItem: container,
                                                     attribute: .centerX,
                                                     multiplier: 1.0,
                                                     constant: 0)

    let leftChoiceSelectionConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: leftChoiceImageView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: container,
                           attribute: .centerX,
                           multiplier: 0.5,
                           constant: 0),
        leftChoiceImageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
        leftChoiceImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
        leftChoiceImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        leftChoiceImageView.widthAnchor.constraint(equalTo: leftChoiceImageView.heightAnchor)
    ]

    let leftChoiceCenterConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: leftChoiceImageView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: container,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0),
        leftChoiceImageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
        leftChoiceImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
        leftChoiceImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        leftChoiceImageView.widthAnchor.constraint(equalTo: leftChoiceImageView.heightAnchor)
    ]

    let rightChoiceSelectionConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: rightChoiceImageView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: container,
                           attribute: .centerX,
                           multiplier: 1.5,
                           constant: 0),
        rightChoiceImageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
        rightChoiceImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
        rightChoiceImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        rightChoiceImageView.widthAnchor.constraint(equalTo: rightChoiceImageView.heightAnchor)
    ]

    let rightChoiceCenterConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: rightChoiceImageView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: container,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0),
        rightChoiceImageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
        rightChoiceImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
        rightChoiceImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        rightChoiceImageView.widthAnchor.constraint(equalTo: rightChoiceImageView.heightAnchor)
    ]

    NSLayoutConstraint.activate([
        versusCenterXConstraint,

        leftChoiceImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        rightChoiceImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        versusSeparatorView.centerYAnchor.constraint(equalTo: container.centerYAnchor),

        scoreLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
        scoreLabel.heightAnchor.constraint(equalToConstant: 28),
        scoreLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        scoreLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),

        scoreTitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
        scoreTitleLabel.bottomAnchor.constraint(equalTo: scoreLabel.topAnchor),
        scoreTitleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
    ]
        + leftChoiceSelectionConstraints
        + rightChoiceSelectionConstraints
    )

    return InteractionViews(container: container,
                            leftChoiceImageView: leftChoiceImageView,
                            rightChoiceImageView: rightChoiceImageView,
                            versusSeparatorView: versusSeparatorView,
                            leftChoiceSelectionConstraints: leftChoiceSelectionConstraints,
                            leftChoiceCenterConstraints: leftChoiceCenterConstraints,
                            rightChoiceSelectionConstraints: rightChoiceSelectionConstraints,
                            rightChoiceCenterConstraints: rightChoiceCenterConstraints,
                            versusSeparatorViewCenterXConstraint: versusCenterXConstraint,
                            scoreLabel: scoreLabel,
                            scoreTitleLabel: scoreTitleLabel)
}

private struct TutorialViews {
    let container: UIView
    let instructionLabel: UILabel
    let countdownLabel: UILabel
    let handImageView: UIImageView
    let pulseCircleView: CircleShapeView
}

private func constructTutorialView() -> TutorialViews {
    let container = constraintBased { UIView(frame: .zero) }
    let instructionLabel = constraintBased { UILabel(frame: .zero) }
    let countdownLabel = constraintBased { UILabel(frame: .zero) }
    let handImageView = constraintBased { UIImageView(frame: .zero) }
    let pulseCircleView = constraintBased { CircleShapeView() }

    container.isUserInteractionEnabled = false

    instructionLabel.alpha = 0
    handImageView.alpha = 0
    pulseCircleView.alpha = 0

    if let handImage = UIImage(named: "cheermeterIcTapping", in: Bundle(for: CheerMeterWidgetView.self), compatibleWith: nil) {
        handImageView.image = handImage
    } else {
        assertionFailure("Failed to loda image with name: cheermeterIcTapping")
    }

    container.addSubview(pulseCircleView)
    container.addSubview(instructionLabel)
    container.addSubview(countdownLabel)
    container.addSubview(handImageView)

    NSLayoutConstraint.activate([
        pulseCircleView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        pulseCircleView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        pulseCircleView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
        pulseCircleView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 1.5),

        instructionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        instructionLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -15),
        instructionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
        instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),

        countdownLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        countdownLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 15),
        countdownLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
        countdownLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),

        handImageView.trailingAnchor.constraint(equalTo: pulseCircleView.trailingAnchor, constant: -16),
        handImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 6),
        handImageView.heightAnchor.constraint(equalToConstant: 44),
        handImageView.widthAnchor.constraint(equalToConstant: 60)
    ])

    return TutorialViews(container: container,
                         instructionLabel: instructionLabel,
                         countdownLabel: countdownLabel,
                         handImageView: handImageView,
                         pulseCircleView: pulseCircleView)
}
