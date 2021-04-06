import EngagementSDK
import UIKit

class TextPredictionFollowUpResultsViewController: UIViewController {
    private let model: PredictionFollowUpWidgetModel

    init(model: PredictionFollowUpWidgetModel) {
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
        model.options.forEach { option in
            let choiceOptionView = CustomTextChoiceWidgetOptionView()
            choiceOptionView.textLabel.text = option.text
            let totalVoteCount = model.options.map { $0.voteCount }.reduce(0, +)
            let percentage = totalVoteCount > 0 ? CGFloat(option.voteCount) / CGFloat(totalVoteCount) : 0
            choiceOptionView.percentageLabel.text = "\(Int(percentage * 100))%"
            choiceOptionView.progress = percentage

            if option.isCorrect {
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
