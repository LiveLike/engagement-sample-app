import EngagementSDK
import UIKit

class CustomTextPollWidgetViewController: Widget {
    private let model: PollWidgetModel

    private var optionViews: [CustomTextChoiceWidgetOptionView] = []

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    var choiceView: CustomTextChoiceWidgetView {
        return view as! CustomTextChoiceWidgetView
    }

    private var selectedOptionIndex: Int?

    override init(model: PollWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let choiceView = CustomTextChoiceWidgetView()

        choiceView.widgetTag.text = "TEXT POLL"
        choiceView.titleLabel.text = model.question
        model.options.enumerated().forEach { index, option in
            let choiceOptionView = CustomTextChoiceWidgetOptionView()
            choiceOptionView.textLabel.text = option.text
            choiceOptionView.percentageLabel.isHidden = true
            choiceOptionView.progressView.isHidden = true
            choiceOptionView.tag = index
            choiceOptionView.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
            choiceView.optionsStackView.addArrangedSubview(choiceOptionView)
            optionViews.append(choiceOptionView)
        }

        choiceView.addSubview(timer)
        timer.topAnchor.constraint(equalTo: choiceView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: choiceView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: choiceView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        view = choiceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.delegate = self
        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) {
            self.choiceView.optionsStackView.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
            }
        }
        model.registerImpression()
    }

    @objc private func optionSelected(_ button: UIButton) {
        if let previousSelectedIndex = selectedOptionIndex {
            let previousSelectedChoiceView = optionViews[previousSelectedIndex]
            previousSelectedChoiceView.backgroundColor = .white
            previousSelectedChoiceView.percentageLabel.textColor = .black
            previousSelectedChoiceView.textLabel.textColor = .black
            previousSelectedChoiceView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0).cgColor
            previousSelectedChoiceView.progressView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        } else {
            // on first selection, reveal percentage label and progress view
            optionViews.forEach {
                $0.percentageLabel.isHidden = false
                $0.progressView.isHidden = false
            }
        }

        guard let choiceView = button as? CustomTextChoiceWidgetOptionView else { return }
        choiceView.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0)
        choiceView.textLabel.textColor = .white
        choiceView.percentageLabel.textColor = .white
        choiceView.backgroundColor = .black
        choiceView.layer.borderColor = UIColor.clear.cgColor
        choiceView.progressView.backgroundColor = UIColor(red: 0/255, green: 150/255, blue: 255/255, alpha: 1.0)

        selectedOptionIndex = button.tag

        let optionID = model.options[button.tag].id
        model.submitVote(optionID: optionID)
    }
}

extension CustomTextPollWidgetViewController: PollWidgetModelDelegate {
    func pollWidgetModel(_ model: PollWidgetModel, voteCountDidChange voteCount: Int, forOption optionID: String) {
        DispatchQueue.main.async {
            guard let optionIndex = model.options.firstIndex(where: { $0.id == optionID }) else { return }
            guard model.totalVoteCount > 0 else { return }
            let votePercentage = (CGFloat(voteCount) / CGFloat(model.totalVoteCount))
            self.optionViews[optionIndex].percentageLabel.text = "\(Int(votePercentage * 100))%"
            self.optionViews[optionIndex].progressViewWidthConstraint.constant = votePercentage * self.optionViews[optionIndex].bounds.width
        }
    }
}
