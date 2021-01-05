//
//  QuizWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import UIKit

class QuizWidgetViewController: Widget {
    // MARK: - Internal Properties

    override var theme: Theme {
        didSet {
            applyTheme(theme)
            self.quizWidget.options.forEach { optionView in
                switch optionView.optionThemeStyle {
                case .unselected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.quiz.unselectedOption
                    )
                case .selected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.quiz.selectedOption
                    )
                case .correct:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.quiz.correctOption
                    )
                case .incorrect:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.quiz.incorrectOption
                    )
                }
            }
        }
    }
    override var currentState: WidgetState {
        willSet {
            previousState = self.currentState
        }
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetDidEnterState(widget: self, state: self.currentState)
                switch self.currentState {
                case .ready:
                    break
                case .interacting:
                    self.enterInteractingState()
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }

    var closeButtonCompletion: ((WidgetViewModel) -> Void)?
    
    // MARK: - Private Stored Properties
    
    private let optionType: ChoiceWidgetOptionButton.Type
    private lazy var quizWidget: ChoiceWidget = {
        let view = VerticalChoiceWidget(optionType: self.optionType)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var myQuizSelection: WidgetOption?
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository
    private var firstTapTime: Date?
    private let model: QuizWidgetModel

    // MARK: - Initializers
    
    override init(model: QuizWidgetModel) {
        self.model = model
        self.optionType = model.containsImages ? WideTextImageChoice.self : TextChoiceWidgetOptionButton.self
        super.init(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    override func moveToNextState() {
        switch self.currentState {
        case .ready:
            self.currentState = .interacting
        case .interacting:
            self.currentState = .results
        case .results:
            self.currentState = .finished
        case .finished:
            break
        }
    }

    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        self.closeButtonCompletion = completion
        quizWidget.titleView.showCloseButton()
    }

    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        quizWidget.titleView.beginTimer(
            duration: seconds,
            animationFilepath: theme.lottieFilepaths.timer
        ) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }
}

// MARK: - View Lifecycle

extension QuizWidgetViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(quizWidget)
        quizWidget.constraintsFill(to: view)
        quizWidget.isUserInteractionEnabled = false
        
        quizWidget.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        quizWidget.titleView.titleLabel.text = widgetTitle
        optionsArray?.forEach { option in
            quizWidget.addOption(withID: option.id) { optionView in
                optionView.text = option.text
                if let imageUrl = option.imageUrl {
                    mediaRepository.getImage(url: imageUrl) { result in
                        switch result {
                        case .success(let imageResult):
                            optionView.image = imageResult.image
                        case .failure(let error):
                            log.error(error)
                        }
                    }
                }
                optionView.delegate = self
                self.applyOptionTheme(
                    optionView: optionView,
                    optionTheme: theme.widgets.quiz.unselectedOption
                )
            }
        }
    
        self.applyTheme(theme)
        self.model.delegate = self

        self.model.registerImpression()
    }
}

// MARK: - WidgetViewModel

extension QuizWidgetViewController {
    
    private func applyTheme(_ theme: Theme) {
        quizWidget.titleView.titleMargins = theme.choiceWidgetTitleMargins
        quizWidget.bodyBackground = theme.widgets.quiz.body.background
        quizWidget.optionSpacing = theme.interOptionSpacing
        quizWidget.headerBodySpacing = theme.titleBodySpacing
        quizWidget.titleView.titleLabel.textColor = theme.widgets.quiz.title.color
        quizWidget.titleView.titleLabel.font = theme.widgets.quiz.title.font
        quizWidget.applyContainerProperties(theme.widgets.quiz.main)
        quizWidget.titleView.applyContainerProperties(theme.widgets.quiz.header)
    }
    
    private func applyOptionTheme(
        optionView: ChoiceWidgetOption,
        optionTheme: Theme.ChoiceWidget.Option?
    ) {
        guard let optionTheme = optionTheme else { return }

        optionView.descriptionFont = optionTheme.description.font
        optionView.descriptionTextColor = optionTheme.description.color
        optionView.percentageFont = optionTheme.percentage.font
        optionView.percentageTextColor = optionTheme.percentage.color
        optionView.barBackground = optionTheme.progressBar.background
        optionView.barCornerRadii = optionTheme.progressBar.cornerRadii
        optionView.applyContainerProperties(optionTheme.container)
    }

    /// Shows results from `WidgetOption` data that already exists
    private func showResultsFromWidgetOptions() {
        guard let quizResults = options else { return }
        let totalVoteCount = quizResults.map { $0.voteCount ?? 0 }.reduce(0, +)
        
        quizWidget.options.forEach { option in
            
            guard let optionData = self.options?.first(where: { $0.id == option.id }) else {
                return
            }
            
            let answerCount = quizResults.first(where: { $0.id == option.id })?.voteCount ?? 0
            let votePercentage: CGFloat = totalVoteCount > 0 ? CGFloat(answerCount) / CGFloat(totalVoteCount) : 0
            let isCorrect = optionData.isCorrect ?? false
            
            if isCorrect {
                self.applyOptionTheme(
                    optionView: option,
                    optionTheme: self.theme.widgets.quiz.correctOption
                )
            } else {
                if votePercentage > 0.0 {
                    self.applyOptionTheme(
                        optionView: option,
                        optionTheme: self.theme.widgets.quiz.incorrectOption
                    )
                    option.borderWidth = 0.0
                }
            }
            
            option.setProgress(votePercentage)
        }
    }

    @objc private func closeButtonPressed() {
        self.closeButtonCompletion?(self)
    }
    
}

// MARK: - Private APIs

private extension QuizWidgetViewController {
    
    // MARK: Handle States
    
    func enterInteractingState() {
        quizWidget.isUserInteractionEnabled = true
        self.interactableState = .openToInteraction
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    func enterResultsState() {
        if let firstTapTime = self.firstTapTime, let lastTapTime = self.timeOfLastInteraction {
            self.model.eventRecorder.record(
                .widgetInteracted(
                    properties: WidgetInteractedProperties(
                        widgetId: self.id,
                        widgetKind: self.kind.analyticsName,
                        firstTapTime: firstTapTime,
                        lastTapTime: lastTapTime,
                        numberOfTaps: self.interactionCount
                    )
                )
            )
        }

        quizWidget.options.forEach {
            $0.isUserInteractionEnabled = false
        }
        self.interactableState = .closedToInteraction
        
        guard let myQuizSelection = self.myQuizSelection else {
            showResultsFromWidgetOptions()
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }

        // Update local option vote data from selection
        if let localOption = options?.first(where: { $0.id == myQuizSelection.id }){
            if let voteCount = localOption.voteCount {
                localOption.voteCount = voteCount + 1
            } else {
                localOption.voteCount = 1
            }
        }
        
        self.model.lockInAnswer(choiceID: myQuizSelection.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.quizWidget.options.forEach { option in
                    guard let optionData = self.options?.first(where: { $0.id == option.id }) else {
                        return
                    }

                    guard let isCorrect = optionData.isCorrect else {
                        return
                    }

                    if isCorrect {
                        option.optionThemeStyle = .correct
                        self.applyOptionTheme(
                            optionView: option,
                            optionTheme: self.theme.widgets.quiz.correctOption
                        )
                    } else if !isCorrect && myQuizSelection.id == optionData.id {
                        option.optionThemeStyle = .incorrect
                        self.applyOptionTheme(
                            optionView: option,
                            optionTheme: self.theme.widgets.quiz.incorrectOption
                        )
                    }
                }
                
                // Optimistically start showing result graph
                // from local data prior to the delegate data
                self.showResultsFromWidgetOptions()

                let animationFilepath: String = {
                    if myQuizSelection.isCorrect ?? false {
                        return self.theme.lottieFilepaths.randomWin()
                    } else {
                        return self.theme.lottieFilepaths.randomLose()
                    }
                }()

                self.quizWidget.playOverlayAnimation(animationFilepath: animationFilepath) {
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                }
            case .failure(let error):
                log.error(error)
            }
        }
    }
    
    func enterFinishedState() {
        // Display results from `WidgetOptions` if entering `finished` state without casting a vote
        if self.myQuizSelection == nil {
            showResultsFromWidgetOptions()
        }
        
        self.quizWidget.stopOverlayAnimation()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}

extension QuizWidgetViewController: QuizWidgetModelDelegate {
    func quizWidgetModel(_ model: QuizWidgetModel, answerCountDidChange voteCount: Int, forChoice optionID: String) {
        guard currentState == .results else { return } // Only update progress while in results state

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let totalVoteCount = model.choices.map { $0.answerCount }.reduce(0, +)
            guard totalVoteCount > 0 else {
                return
            }
            guard let optionView = self.quizWidget.options.first(where: { $0.id == optionID }) else { return }
            optionView.setProgress((CGFloat(voteCount) / CGFloat(totalVoteCount)))
        }
    }
}

extension QuizWidgetViewController: ChoiceWidgetOptionDelegate {
    func wasSelected(_ option: ChoiceWidgetOption) {

        // Ignore repeated selections
        guard myQuizSelection?.id != option.id else { return }

        guard let opt = options?.first(where: { $0.id == option.id }) else {
            return
        }
        self.userDidInteract = true
        
        self.myQuizSelection = opt
        
        quizWidget.options.forEach {
            $0.optionThemeStyle = .unselected
            self.applyOptionTheme(
                optionView: $0,
                optionTheme: theme.widgets.quiz.unselectedOption
            )
        }
        option.optionThemeStyle = .selected
        self.applyOptionTheme(
            optionView: option,
            optionTheme: theme.widgets.quiz.selectedOption
        )

        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        timeOfLastInteraction = now
        interactionCount += 1
        self.delegate?.userDidInteract(self)
    }
    
    func wasDeselected(_ option: ChoiceWidgetOption) {
    
    }
}
