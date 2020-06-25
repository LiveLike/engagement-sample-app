//
//  TextPollWidgetView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/20/19.
//

import UIKit

class TextPollWidgetView: VerticalChoiceWidget, PollWidget {
    struct OptionData {
        let id: String
        let description: String
        let imageURL: URL?
        let voteURL: URL
    }

    private var optionButtons = [ChoiceWidgetOptionButton]()

    private let pollTheme: PollWidgetTheme
    private let theme: Theme
    private let widgetConfig: WidgetConfig
    private var selectedOptionID: String?
    private let choiceOptionFactory: ChoiceWidgetOptionFactory

    private let question: String
    private let timeout: TimeInterval
    private let optionData: [OptionData]
    private let optionStyle: ChoiceWidgetOptionFactory.Style

    var onSelectionAction: ((PollSelection) -> Void)?

    private var closeAction: (() -> Void)?

    init(data: ImagePollCreated, theme: Theme, choiceOptionFactory: ChoiceWidgetOptionFactory, widgetConfig: WidgetConfig) {
        question = data.question
        timeout = data.timeout.timeInterval
        pollTheme = theme.pollWidget
        self.theme = theme
        self.choiceOptionFactory = choiceOptionFactory
        self.widgetConfig = widgetConfig
        optionStyle = .wideTextImage
        optionData = data.options.map { OptionData(id: $0.id, description: $0.description, imageURL: $0.imageUrl, voteURL: $0.voteUrl) }
        super.init()
        configure()
    }

    init(data: TextPollCreated, theme: Theme, choiceOptionFactory: ChoiceWidgetOptionFactory, widgetConfig: WidgetConfig) {
        question = data.question
        timeout = data.timeout.timeInterval
        pollTheme = theme.pollWidget
        self.theme = theme
        self.choiceOptionFactory = choiceOptionFactory
        self.widgetConfig = widgetConfig
        optionStyle = .wideText
        optionData = data.options.map { OptionData(id: $0.id, description: $0.description, imageURL: nil, voteURL: $0.voteUrl) }
        super.init()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    private func configure() {
        titleView.titleLabel.text = theme.uppercaseTitleText ? question.uppercased() : question
        titleView.titleMargins = theme.choiceWidgetTitleMargins
        customize(pollTheme, theme: theme)

        let textChoices: [ChoiceWidgetOptionButton] = optionData.map { option in
            let textChoice: ChoiceWidgetOptionButton = choiceOptionFactory.create(style: self.optionStyle, id: option.id)
            textChoice.customize(theme)
            textChoice.setText(option.description, theme: theme)
            if let imageURL = option.imageURL {
                textChoice.setImage(imageURL)
            }
            textChoice.onButtonPressed = { [weak self] in
                guard let self = self else { return }
                self.handleTextChoiceOptionPressed($0)
                self.selectedOptionID = option.id
                self.onSelectionAction?((option.id, option.voteURL))
            }
            return textChoice
        }

        populateStackView(options: textChoices)
        optionButtons = textChoices
    }

    func beginTimer(seconds: TimeInterval, completion: @escaping () -> Void) {
        titleView.beginTimer(duration: seconds,
                             animationFilepath: theme.filepathsForWidgetTimerLottieAnimation,
                             completion: completion)
    }
    
    func showCloseButton(completion: @escaping () -> Void) {
        self.closeAction = completion
        self.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        self.titleView.showCloseButton()
    }

    @objc private func closeButtonPressed() {
        closeAction?()
    }

    func setOptionsLocked(_ lock: Bool) {
        for optionButton in optionButtons {
            optionButton.isUserInteractionEnabled = !lock
        }
    }

    func revealResults() {
        for optionButton in optionButtons {
            if optionButton.id != selectedOptionID {
                optionButton.setColors(theme.neutralOptionColors)
            } else {
                optionButton.setColors(pollTheme.selectedColors)
            }
        }
    }

    func updateResults(results: PollResults) {
        let totalVotes = results.options.map { $0.voteCount }.reduce(0, +)

        for optionButton in optionButtons {
            for updateOption in results.options where optionButton.id == updateOption.id {
                var percent: CGFloat = 0.0
                if totalVotes > 0 {
                    percent = CGFloat(updateOption.voteCount) / CGFloat(totalVotes)
                }
                optionButton.setProgress(percent)
            }
        }
    }

    private func handleTextChoiceOptionPressed(_ textChoice: ChoiceWidgetOptionButton) {
        // deslect other options
        for option in optionButtons {
            option.setColors(theme.neutralOptionColors)
            option.isUserInteractionEnabled = true
            option.isSelected = false
        }
        textChoice.isUserInteractionEnabled = false // don't allow re-select
        textChoice.isSelected = true
        textChoice.setColors(pollTheme.selectedColors)
    }
}
