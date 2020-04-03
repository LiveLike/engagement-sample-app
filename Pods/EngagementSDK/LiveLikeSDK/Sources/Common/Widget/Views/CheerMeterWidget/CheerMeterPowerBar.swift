//
//  CheerMeterPowerBar.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/26/19.
//

import UIKit

class CheerMeterPowerBar: UIView {
    private let leftChoiceLabel: UILabel
    private let rightChoiceLabel: UILabel
    private let leftChoiceBar: GradientView
    private let rightChoiceBar: GradientView
    private let leftChoiceFlashView: UIView
    private let rightChoiceFlashView: UIView
    private var leftGradientWidthConstraint: NSLayoutConstraint!

    private var theme: Theme?

    var leftChoiceText: String {
        get { return leftChoiceLabel.text ?? "" }
        set { leftChoiceLabel.text = newValue }
    }

    var rightChoiceText: String {
        get { return rightChoiceLabel.text ?? "" }
        set { rightChoiceLabel.text = newValue }
    }

    var leftScore: Int = 0 {
        didSet {
            updateWidthConstraint()
        }
    }

    var rightScore: Int = 0 {
        didSet {
            updateWidthConstraint()
        }
    }

    var shouldUpdateWidths: Bool = false

    init() {
        leftChoiceBar = constraintBased { GradientView(orientation: .horizontal) }
        leftChoiceFlashView = constraintBased {
            let view = UIView(frame: .zero)
            view.backgroundColor = .white
            view.alpha = 0
            return view
        }

        leftChoiceLabel = constraintBased { UILabel(frame: .zero) }

        rightChoiceBar = constraintBased { GradientView(orientation: .horizontal) }

        rightChoiceFlashView = constraintBased {
            let view = UIView(frame: .zero)
            view.backgroundColor = .white
            view.alpha = 0
            return view
        }

        rightChoiceLabel = constraintBased { UILabel(frame: .zero) }

        super.init(frame: .zero)

        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateWidthConstraint()
    }

    private func updateWidthConstraint() {
        let totalScore: Int = leftScore + rightScore
        guard shouldUpdateWidths, totalScore > 0 else {
            leftGradientWidthConstraint.constant = bounds.width * 0.5
            return
        }

        leftGradientWidthConstraint.constant = bounds.width * (CGFloat(leftScore) / CGFloat(totalScore))
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
        })
    }

    private func configureLayout() {
        addSubview(leftChoiceBar)
        addSubview(leftChoiceLabel)
        addSubview(rightChoiceBar)
        addSubview(rightChoiceLabel)

        leftGradientWidthConstraint = leftChoiceBar.widthAnchor.constraint(equalToConstant: bounds.width * 0.5)
        NSLayoutConstraint.activate([
            rightChoiceBar.leadingAnchor.constraint(equalTo: leftChoiceBar.trailingAnchor),
            rightChoiceBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightChoiceBar.topAnchor.constraint(equalTo: topAnchor),
            rightChoiceBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftGradientWidthConstraint,
            leftChoiceBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftChoiceBar.topAnchor.constraint(equalTo: topAnchor),
            leftChoiceBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftChoiceLabel.centerXAnchor.constraint(equalTo: leftChoiceBar.centerXAnchor),
            leftChoiceLabel.centerYAnchor.constraint(equalTo: leftChoiceBar.centerYAnchor),
            leftChoiceLabel.widthAnchor.constraint(lessThanOrEqualTo: leftChoiceBar.widthAnchor),
            leftChoiceLabel.heightAnchor.constraint(equalTo: leftChoiceBar.heightAnchor),

            rightChoiceLabel.centerXAnchor.constraint(equalTo: rightChoiceBar.centerXAnchor),
            rightChoiceLabel.centerYAnchor.constraint(equalTo: rightChoiceBar.centerYAnchor),
            rightChoiceLabel.widthAnchor.constraint(lessThanOrEqualTo: rightChoiceBar.widthAnchor),
            rightChoiceLabel.heightAnchor.constraint(equalTo: rightChoiceBar.heightAnchor)

        ])

        leftChoiceBar.addSubview(leftChoiceFlashView)
        rightChoiceBar.addSubview(rightChoiceFlashView)

        leftChoiceFlashView.constraintsFill(to: leftChoiceBar)
        rightChoiceFlashView.constraintsFill(to: rightChoiceBar)
    }
}

// MARK: Animations

extension CheerMeterPowerBar {
    enum Side {
        case left
        case right
    }

    func flashLeft() {
        flash(view: leftChoiceFlashView)
    }

    func flashRight() {
        flash(view: rightChoiceFlashView)
    }

    private func flash(view: UIView) {
        view.alpha = 0
        UIView.animate(withDuration: 0.05, animations: {
            view.alpha = 1
        }, completion: { complete in
            if complete {
                UIView.animate(withDuration: 0.05, animations: {
                    view.alpha = 0
                })
            }
        })
    }
}

extension CheerMeterPowerBar {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        leftChoiceLabel.font = theme.cheerMeter.teamOneFont
        leftChoiceLabel.textColor = theme.cheerMeter.teamOneTextColor
        leftChoiceBar.livelike_startColor = theme.cheerMeter.teamOneLeftColor
        leftChoiceBar.livelike_endColor = theme.cheerMeter.teamOneRightColor

        rightChoiceLabel.font = theme.cheerMeter.teamTwoFont
        rightChoiceLabel.textColor = theme.cheerMeter.teamTwoTextColor
        rightChoiceBar.livelike_startColor = theme.cheerMeter.teamTwoLeftColor
        rightChoiceBar.livelike_endColor = theme.cheerMeter.teamTwoRightColor
    }
}
