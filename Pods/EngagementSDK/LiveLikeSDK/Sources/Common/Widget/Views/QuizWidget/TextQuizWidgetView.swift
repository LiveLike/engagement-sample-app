//
//  TextQuizWidgetView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import UIKit

class TextQuizWidgetView: VerticalChoiceWidget, QuizWidget {
    // MARK: Internal Properties

    var didSelectChoice: ((QuizSelection) -> Void)?

    // MARK: Private Properties

    private let data: TextQuizCreated
    private let quizTheme: QuizWidgetTheme
    private let theme: Theme
    private let widgetConfig: WidgetConfig

    private var choiceViews = [TextChoiceWidgetOptionButton]()
    private var closeButtonAction: (() -> Void)?

    init(data: TextQuizCreated, theme: Theme, widgetConfig: WidgetConfig) {
        self.data = data
        quizTheme = theme.quizWidget
        self.theme = theme
        self.widgetConfig = widgetConfig
        super.init()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    private func configure() {
        self.clipsToBounds = true
        customize(quizTheme, theme: theme)
        titleView.titleLabel.text = theme.uppercaseTitleText ? data.question.uppercased() : data.question
        titleView.titleMargins = theme.choiceWidgetTitleMargins

        choiceViews = data.choices.map { choice in
            let choiceView = TextChoiceWidgetOptionButton(id: choice.id)
            choiceView.customize(theme)
            choiceView.setText(choice.description, theme: theme)
            choiceView.onButtonPressed = { _ in
                self.didSelectChoice?((optionId: choice.id, answerUrl: choice.answerUrl))
                self.deselectAllChoices()
                self.selectChoiceView(choiceView)
            }
            return choiceView
        }

        populateStackView(options: choiceViews)
    }

    private func selectChoiceView(_ choiceView: TextChoiceWidgetOptionButton) {
        // highlight choice
        choiceView.isSelected = true
        choiceView.livelike_borderColor = quizTheme.optionSelectBorderColor
    }

    private func deselectAllChoices() {
        for choiceView in choiceViews {
            choiceView.isSelected = false
            choiceView.livelike_borderColor = theme.neutralOptionColors.borderColor
        }
    }

    func beginTimer(seconds: TimeInterval, completion: @escaping () -> Void) {
        titleView.beginTimer(
            duration: seconds,
            animationFilepath: theme.filepathsForWidgetTimerLottieAnimation
        ) {
            completion()
        }
    }

    func showCloseButton(completion: @escaping () -> Void) {
        closeButtonAction = completion
        titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        titleView.showCloseButton()
    }

    @objc private func closeButtonPressed() {
        closeButtonAction?()
    }

    func revealAnswer(myOptionId: String?, completion: (() -> Void)?) {
        let correctOptions: [String] = data.choices.filter { $0.isCorrect }.map { $0.id }
        // show percentage on all choices
        // show correct answer and if my choice was incorrect
        for choiceView in choiceViews {
            let isCorrect = correctOptions.contains(choiceView.id)
            if isCorrect {
                choiceView.setColors(theme.correctOptionColors)
                continue
            }

            if choiceView.id == myOptionId, !isCorrect {
                choiceView.setColors(theme.incorrectOptionColors)
                continue
            }

            choiceView.setColors(theme.neutralOptionColors)
        }

        // play incorrect animation if my option is wrong or missing
        if
            let myOption = myOptionId,
            correctOptions.contains(myOption)
        {
            playOverlayAnimation(animationFilepath: theme.randomCorrectAnimationAsset(),
                                 completion: completion)
        } else {
            playOverlayAnimation(animationFilepath: theme.randomIncorrectAnimationAsset(),
                                 completion: completion)
        }
    }

    func updateResults(_ results: QuizResults) {
        let totalVotes = results.choices.map { $0.answerCount }.reduce(0, +)
        for choiceView in choiceViews {
            for result in results.choices where choiceView.id == result.id {
                // calculate progress
                var percent: CGFloat = 0.0
                if totalVotes > 0 {
                    percent = CGFloat(result.answerCount) / CGFloat(totalVotes)
                }
                // set progress
                choiceView.setProgress(percent)
                break
            }
        }
    }

    func lockSelection() {
        for choiceView in choiceViews {
            choiceView.isUserInteractionEnabled = false
        }
    }
    
    func stopAnswerRevealAnimation() {
        stopOverlayAnimation()
    }
}
