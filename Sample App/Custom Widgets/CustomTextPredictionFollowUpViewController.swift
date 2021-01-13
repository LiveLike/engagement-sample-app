import EngagementSDK
import UIKit

class CustomTextPredictionFollowUpWidgetViewController: Widget {
    private let model: PredictionFollowUpWidgetModel

    private var optionViews: [CustomTextChoiceWidgetOptionView] = []

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    var choiceView: CustomTextChoiceWidgetView {
        return view as! CustomTextChoiceWidgetView
    }

    override init(model: PredictionFollowUpWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let choiceView = CustomTextChoiceWidgetView()

        choiceView.widgetTag.text = "TEXT PREDICTION FOLLOW UP"
        choiceView.titleLabel.text = model.question
        model.options.enumerated().forEach { _, option in
            let optionView = CustomTextChoiceWidgetOptionView()
            optionView.textLabel.text = option.text
            optionView.progressView.isHidden = false
            choiceView.optionsStackView.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }

        choiceView.addSubview(timer)
        timer.bottomAnchor.constraint(equalTo: choiceView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: choiceView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: choiceView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        view = choiceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.getVote { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(vote):
                    guard let optionIndex = self.model.options.firstIndex(where: { $0.id == vote.optionID }) else { return }
                    let optionView = self.optionViews[optionIndex]
                    optionView.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0)
                    optionView.textLabel.textColor = .white
                    optionView.percentageLabel.textColor = .white
                    optionView.layer.borderColor = UIColor.clear.cgColor

                    let totalVotes = self.model.options.map { $0.voteCount }.reduce(0, +)
                    self.model.options.enumerated().forEach { index, option in
                        let optionView = self.optionViews[index]
                        let votePercentage: CGFloat = totalVotes > 0 ? CGFloat(option.voteCount) / CGFloat(totalVotes) : 0
                        optionView.percentageLabel.text = "\(Int(votePercentage * 100))%"
                        if option.isCorrect {
                            optionView.progressView.backgroundColor = UIColor(red: 0/255, green: 255/255, blue: 120/255, alpha: 1.0)
                        } else if option.isCorrect, option.id == vote.id {
                            optionView.progressViewWidthConstraint.constant = votePercentage * optionView.bounds.width
                        }
                        optionView.progressViewWidthConstraint.constant = votePercentage * optionView.bounds.width
                    }
                    if !self.model.options[optionIndex].isCorrect {
                        optionView.progressView.backgroundColor = UIColor(red: 255/255, green: 60/255, blue: 60/255, alpha: 1.0)
                    }
                case let .failure(error):
                    print(error)
                }
            }
        }

        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) {
            self.delegate?.widgetDidEnterState(widget: self, state: .finished)
        }
    }
}
