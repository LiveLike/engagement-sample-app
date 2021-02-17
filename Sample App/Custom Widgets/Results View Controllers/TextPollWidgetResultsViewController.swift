import EngagementSDK
import UIKit

class TextPollWidgetResultsViewController: UIViewController {
    private let model: PollWidgetModel

    init(model: PollWidgetModel) {
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
            let percentage = model.totalVoteCount > 0 ? CGFloat(option.voteCount) / CGFloat(model.totalVoteCount) : 0
            choiceOptionView.percentageLabel.text = "\(Int(percentage * 100))%"
            choiceOptionView.progress = percentage
            choiceOptionView.progressView.backgroundColor = WidgetViewHelpers.colors.gray
            choiceView.optionsStackView.addArrangedSubview(choiceOptionView)
        }

        view = choiceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.registerImpression()
    }
}
