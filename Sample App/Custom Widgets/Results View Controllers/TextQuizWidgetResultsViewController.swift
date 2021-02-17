import EngagementSDK
import UIKit

class TextQuizWidgetResultsViewController: UIViewController {
    private let model: QuizWidgetModel

    init(model: QuizWidgetModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let choiceView = CustomTextChoiceWidgetView()
        choiceView.translatesAutoresizingMaskIntoConstraints = false
        choiceView.titleLabel.text = model.question
        model.choices.forEach { choice in
            let choiceOptionView = CustomTextChoiceWidgetOptionView()
            choiceOptionView.textLabel.text = choice.text
            let percentage = model.totalAnswerCount > 0 ? CGFloat(choice.answerCount) / CGFloat(model.totalAnswerCount) : 0
            choiceOptionView.percentageLabel.text = "\(Int(percentage * 100))%"
            choiceOptionView.progress = percentage

            if choice.isCorrect {
                choiceOptionView.progressView.backgroundColor = WidgetViewHelpers.colors.green
            } else {
                choiceOptionView.progressView.backgroundColor = WidgetViewHelpers.colors.gray
            }
            choiceView.optionsStackView.addArrangedSubview(choiceOptionView)
        }

        view = choiceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.registerImpression()
    }
}
