//
//  PredictionFollowUpViewController.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/22/19.
//

import UIKit

class PredictionFollowUpViewController: Widget {

    override var theme: Theme {
        didSet {
            self.applyTheme(theme)
            widgetView.options.forEach { optionView in
                switch optionView.optionThemeStyle {
                case .correct:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.prediction.correctOption
                    )
                case .incorrect:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.prediction.incorrectOption
                    )
                case .unselected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.prediction.unselectedOption
                    )
                default:
                    break
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
                    break
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }

    private(set) lazy var widgetView: ChoiceWidget = {
        // build view
        let verticalChoiceWidget = VerticalChoiceWidget(optionType: self.optionType)
        verticalChoiceWidget.translatesAutoresizingMaskIntoConstraints = false
        return verticalChoiceWidget
    }()

    private let optionType: ChoiceWidgetOptionButton.Type
    private var closeButtonAction: (() -> Void)?

    private let model: PredictionFollowUpWidgetModel
    private var optionButtons = [ChoiceWidgetOptionButton]()
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository

    override init(model: PredictionFollowUpWidgetModel) {
        self.model = model
        if model.containsImages {
            self.optionType = WideTextImageChoice.self
        } else {
            self.optionType = TextChoiceWidgetOptionButton.self
        }
        super.init(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view.addSubview(widgetView)
        widgetView.constraintsFill(to: view)
        widgetView.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        let totalVotes = self.options?.map{ $0.voteCount ?? 0 }.reduce(0, +) ?? 0

        widgetView.titleView.titleLabel.text = widgetTitle
        self.optionsArray?.forEach { optionData in
            widgetView.addOption(withID: optionData.id) { optionView in
                optionView.text = optionData.text
                if let imageURL = optionData.imageUrl {
                    mediaRepository.getImage(url: imageURL) { result in
                        switch result {
                        case .success(let imageResult):
                            optionView.image = imageResult.image
                        case .failure(let error):
                            log.error(error)
                        }
                    }
                }

                if totalVotes == 0 {
                    optionView.setProgress(0)
                } else if let voteCount = optionData.voteCount, totalVotes > 0 {
                    let progress: CGFloat = CGFloat(voteCount) / CGFloat(totalVotes)
                    optionView.setProgress(progress)
                }

                optionView.optionThemeStyle = .unselected
                self.applyOptionTheme(
                    optionView: optionView,
                    optionTheme: theme.widgets.prediction.unselectedOption
                )
            }
        }

        self.model.registerImpression()
        self.applyTheme(theme)
    }

    @objc func closeButtonPressed() {
        closeButtonAction?()
    }
    
    private func applyTheme(_ theme: Theme) {
        widgetView.titleView.titleMargins = theme.choiceWidgetTitleMargins
        widgetView.applyContainerProperties(theme.widgets.prediction.main)
        widgetView.titleView.applyContainerProperties(theme.widgets.prediction.header)
        widgetView.bodyBackground = theme.widgets.prediction.body.background
        widgetView.titleView.titleLabel.textColor = theme.widgets.prediction.title.color
        widgetView.titleView.titleLabel.font = theme.widgets.prediction.title.font
    }

    private func applyOptionTheme(
        optionView: ChoiceWidgetOption,
        optionTheme: Theme.ChoiceWidget.Option?
    ) {
        guard let optionTheme = optionTheme else { return }
        optionView.applyContainerProperties(optionTheme.container)
        optionView.descriptionTextColor = optionTheme.description.color
        optionView.descriptionFont = optionTheme.description.font
        optionView.barBackground = optionTheme.progressBar.background
        optionView.percentageFont = optionTheme.percentage.font
        optionView.percentageTextColor = optionTheme.percentage.color

        DispatchQueue.main.async {
            optionView.barCornerRadii = optionTheme.progressBar.cornerRadii
        }
    }

    private func highlightOptionView(widgetOptionButton: ChoiceWidgetOption, vote: PredictionVote?) {
        guard let option = model.options.first(where: { $0.id == widgetOptionButton.id }) else { return }
        // highlight correct options
        if option.isCorrect {
            widgetOptionButton.optionThemeStyle = .correct
            self.applyOptionTheme(
                optionView: widgetOptionButton,
                optionTheme: theme.widgets.prediction.correctOption
            )
            return
        }
        
        // highlight incorrect option
        if !option.isCorrect {
            if widgetOptionButton.id == vote?.optionID {
                widgetOptionButton.optionThemeStyle = .incorrect
                self.applyOptionTheme(
                    optionView: widgetOptionButton,
                    optionTheme: theme.widgets.prediction.incorrectOption
                )
                return
            }
        }
        
        // otherwise highlight gray
        widgetOptionButton.optionThemeStyle = .unselected
        self.applyOptionTheme(
            optionView: widgetOptionButton,
            optionTheme: theme.widgets.prediction.unselectedOption
        )
    }
    
    override func moveToNextState() {
        switch self.currentState {
        case .ready:
            self.currentState = .results
        case .interacting:
            break
        case .results:
            self.currentState = .finished
        case .finished:
            break
        }
    }
    
    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        self.closeButtonAction = { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
        widgetView.titleView.showCloseButton()
    }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }
    
    private func enterResultsState() {
        self.model.getVote { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let vote):
                self.model.claimRewards(vote: vote)
                self.widgetView.options.forEach { self.highlightOptionView(widgetOptionButton: $0, vote: vote) }
                guard let option = self.model.options.first(where: { $0.id == vote.optionID }) else {
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                    return
                }
                let animationAsset = option.isCorrect ?
                    self.theme.lottieFilepaths.randomWin() :
                    self.theme.lottieFilepaths.randomLose()
                self.widgetView.playOverlayAnimation(animationFilepath: animationAsset) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                }
            case .failure(let error):
                log.error(error)
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        }
    }
    
    private func enterFinishedState() {
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}
