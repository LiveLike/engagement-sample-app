//
//  ImageQuizWidgetView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/25/19.
//

import UIKit

class ImageQuizWidgetView: VerticalChoiceWidget, QuizWidget {
    var didSelectChoice: ((QuizSelection) -> Void)?

    private let data: ImageQuizCreated
    private let quizTheme: QuizWidgetTheme
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private var closeButtonAction: (() -> Void)?
    private let choiceOptionFactory: ChoiceWidgetOptionFactory = ChoiceWidgetOptionFactory()
    private let quizButtonStyle: ChoiceWidgetOptionFactory.Style
    private var quizOptionButtons = [ChoiceWidgetOptionButton]()

    init(data: ImageQuizCreated, theme: Theme, widgetConfig: WidgetConfig) {
        self.data = data
        quizTheme = theme.quizWidget
        self.theme = theme
        self.widgetConfig = widgetConfig
        quizButtonStyle = .wideTextImage
        super.init()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    private func configure() {
        customize(quizTheme, theme: theme)
        titleView.titleLabel.text = theme.uppercaseTitleText ? data.question.uppercased() : data.question
        titleView.titleMargins = theme.choiceWidgetTitleMargins

        let quizChoices: [ChoiceWidgetOptionButton] = data.choices.map { quizChoice in
            let quizChoiceButton: ChoiceWidgetOptionButton = choiceOptionFactory.create(style: self.quizButtonStyle, id: quizChoice.id)
            quizChoiceButton.customize(theme)
            quizChoiceButton.setText(quizChoice.description, theme: theme)
            quizChoiceButton.setImage(quizChoice.imageUrl)

            quizChoiceButton.onButtonPressed = { _ in
                self.didSelectChoice?((optionId: quizChoice.id, answerUrl: quizChoice.answerUrl))
                self.deselectAllChoices()
                self.selectChoiceView(quizChoiceButton)
            }
            return quizChoiceButton
        }

        populateStackView(options: quizChoices)
        quizOptionButtons = quizChoices
    }

    @objc private func closeButtonPressed() {
        closeButtonAction?()
    }
}

// MARK: - Picked Answer Functionality

extension ImageQuizWidgetView {
    func revealAnswer(myOptionId: String?, completion:(() -> Void)?) {
        let correctOptions: [String] = data.choices.filter { $0.isCorrect }.map { $0.id }
        // show percentage on all choices
        // show correct answer and if my choice was incorrect
        for quizOptionButton in quizOptionButtons {
            let isCorrect = correctOptions.contains(quizOptionButton.id)
            if isCorrect {
                quizOptionButton.setColors(theme.correctOptionColors)
                continue
            }

            if quizOptionButton.id == myOptionId, !isCorrect {
                quizOptionButton.setColors(theme.incorrectOptionColors)
                continue
            }

            quizOptionButton.setColors(theme.neutralOptionColors)
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
        for choiceView in quizOptionButtons {
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
}

// MARK: - Timer Functionality

extension ImageQuizWidgetView {
    func beginTimer(seconds: TimeInterval, completion: @escaping () -> Void) {
        titleView.beginTimer(duration: seconds, animationFilepath: theme.filepathsForWidgetTimerLottieAnimation) {
            completion()
        }
    }
    
    func showCloseButton(completion: @escaping () -> Void) {
        closeButtonAction = completion
        titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        titleView.showCloseButton()
    }
}

// MARK: - Select Quiz Choice Functionality

extension ImageQuizWidgetView {
    private func deselectAllChoices() {
        for choiceView in quizOptionButtons {
            choiceView.livelike_borderColor = theme.neutralOptionColors.borderColor
            choiceView.isSelected = false
        }
    }

    private func selectChoiceView(_ choiceView: ChoiceWidgetOptionButton) {
        // highlight choice
        choiceView.livelike_borderColor = quizTheme.optionSelectBorderColor
        choiceView.isSelected = true
    }

    func lockSelection() {
        for quizOptionButton in quizOptionButtons {
            quizOptionButton.isUserInteractionEnabled = false
        }
    }
    
    func stopAnswerRevealAnimation() {
        stopOverlayAnimation()
    }
}
