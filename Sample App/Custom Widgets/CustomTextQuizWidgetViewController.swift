import EngagementSDK
import Lottie
import UIKit

class CustomTextQuizWidgetViewController: Widget {
    private let model: QuizWidgetModel

    private var choiceViews: [CustomTextChoiceWidgetOptionView] = []

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    let resultAnimationView: AnimationView = {
        let animationView = AnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.isUserInteractionEnabled = false
        return animationView
    }()

    var choiceView: CustomTextChoiceWidgetView {
        return view as! CustomTextChoiceWidgetView
    }

    private var selectedChoiceIndex: Int?

    override init(model: QuizWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let choiceView = CustomTextChoiceWidgetView()

        choiceView.widgetTag.text = "TEXT QUIZ"
        choiceView.titleLabel.text = model.question
        model.choices.enumerated().forEach { index, option in
            let choiceOptionView = CustomTextChoiceWidgetOptionView()
            choiceOptionView.textLabel.text = option.text
            choiceOptionView.percentageLabel.isHidden = true
            choiceOptionView.progressView.isHidden = true
            choiceOptionView.tag = index
            choiceOptionView.addTarget(self, action: #selector(choiceSelected(_:)), for: .touchUpInside)
            choiceView.optionsStackView.addArrangedSubview(choiceOptionView)
            choiceViews.append(choiceOptionView)
        }

        choiceView.addSubview(timer)
        timer.topAnchor.constraint(equalTo: choiceView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: choiceView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: choiceView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        choiceView.addSubview(resultAnimationView)
        resultAnimationView.topAnchor.constraint(equalTo: choiceView.topAnchor).isActive = true
        resultAnimationView.leadingAnchor.constraint(equalTo: choiceView.leadingAnchor).isActive = true
        resultAnimationView.trailingAnchor.constraint(equalTo: choiceView.trailingAnchor).isActive = true
        resultAnimationView.bottomAnchor.constraint(equalTo: choiceView.bottomAnchor).isActive = true

        view = choiceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.delegate = self
        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) {
            self.choiceView.optionsStackView.isUserInteractionEnabled = false
            guard let selectedChoiceIndex = self.selectedChoiceIndex else {
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
                return
            }

            let selectedChoiceID = self.model.choices[selectedChoiceIndex].id
            self.model.lockInAnswer(choiceID: selectedChoiceID) { result in
                switch result {
                case .success:
                    print("Successfully locked in answer.")
                case let .failure(error):
                    print("Failed to lock in answer with error: \(error)")
                }
            }

            self.model.choices.enumerated().forEach { index, choice in
                let choiceView = self.choiceViews[index]
                choiceView.progressView.isHidden = false
                choiceView.percentageLabel.isHidden = false
                if choice.isCorrect {
                    choiceView.progressView.backgroundColor = UIColor(red: 0/255, green: 255/255, blue: 120/255, alpha: 1.0)
                } else if !choice.isCorrect, choice.id == selectedChoiceID {
                    choiceView.progressView.backgroundColor = UIColor(red: 255/255, green: 60/255, blue: 60/255, alpha: 1.0)
                }
            }

            if
                let selectedChoice = self.model.choices.first(where: { $0.id == selectedChoiceID }),
                selectedChoice.isCorrect
            {
                self.resultAnimationView.animation = Animation.filepath(Theme().lottieFilepaths.win.randomElement()!)
            } else {
                self.resultAnimationView.animation = Animation.filepath(Theme().lottieFilepaths.lose.randomElement()!)
            }
            self.resultAnimationView.play { _ in
                self.resultAnimationView.isHidden = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
            }
        }
        model.markAsInteractive()
        model.registerImpression()
    }

    @objc private func choiceSelected(_ button: UIButton) {
        if let previousSelectedIndex = selectedChoiceIndex {
            let previousSelectedChoiceView = choiceViews[previousSelectedIndex]
            previousSelectedChoiceView.backgroundColor = .white
            previousSelectedChoiceView.percentageLabel.textColor = .black
            previousSelectedChoiceView.textLabel.textColor = .black
            previousSelectedChoiceView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0).cgColor
            previousSelectedChoiceView.progressView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        }

        guard let choiceView = button as? CustomTextChoiceWidgetOptionView else { return }
        choiceView.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0)
        choiceView.textLabel.textColor = .white
        choiceView.percentageLabel.textColor = .white
        choiceView.backgroundColor = .black
        choiceView.layer.borderColor = UIColor.clear.cgColor
        choiceView.progressView.backgroundColor = UIColor(red: 0/255, green: 150/255, blue: 255/255, alpha: 1.0)

        selectedChoiceIndex = button.tag
    }
}

extension CustomTextQuizWidgetViewController: QuizWidgetModelDelegate {
    func quizWidgetModel(_ model: QuizWidgetModel, answerCountDidChange answerCount: Int, forChoice choiceID: String) {
        DispatchQueue.main.async {
            guard let optionIndex = model.choices.firstIndex(where: { $0.id == choiceID }) else { return }
            guard model.totalAnswerCount > 0 else { return }
            let votePercentage = (CGFloat(answerCount) / CGFloat(model.totalAnswerCount))
            self.choiceViews[optionIndex].percentageLabel.text = "\(Int(votePercentage * 100))%"
            self.choiceViews[optionIndex].progressViewWidthConstraint.constant = votePercentage * self.choiceViews[optionIndex].bounds.width
        }
    }
}
