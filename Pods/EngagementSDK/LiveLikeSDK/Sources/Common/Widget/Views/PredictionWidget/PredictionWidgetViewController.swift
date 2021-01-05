//
//  TextPredictionWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-28.
//

import Lottie
import UIKit

/// Game logic for prediction widgets
class PredictionWidgetViewController: Widget {

    // MARK: Properties

    override var theme: Theme {
        didSet {
            self.applyTheme(theme)
            self.predictionWidgetView.options.forEach { optionView in
                switch optionView.optionThemeStyle {
                case .selected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.prediction.selectedOption
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
                    self.enterInteractingState()
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }
    
    // MARK: Private Properties

    private var currentSelection: ChoiceWidgetOption?
    private var canShowResults: Bool = false
    private var closeButtonAction: (() -> Void)?
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository
    private let model: PredictionWidgetModel
    private var firstTapTime: Date?

    // MARK: View Properties
    
    private let optionType: ChoiceWidgetOptionButton.Type
    private(set) lazy var predictionWidgetView: ChoiceWidget = {
        let textChoiceWidget = VerticalChoiceWidget(optionType: self.optionType)
        textChoiceWidget.translatesAutoresizingMaskIntoConstraints = false
        return textChoiceWidget
    }()

    override init(model: PredictionWidgetModel) {
        self.model = model
        if model.containsImages {
            self.optionType = WideTextImageChoice.self
        } else {
            self.optionType = TextChoiceWidgetOptionButton.self
        }
        super.init(model: model)

        self.predictionWidgetView.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view.addSubview(predictionWidgetView)
        predictionWidgetView.constraintsFill(to: view)

        predictionWidgetView.titleView.closeButton.addTarget(self, action: #selector(onCloseButtonPressed), for: .touchUpInside)
        predictionWidgetView.titleView.titleLabel.text = widgetTitle
 
        self.optionsArray?.forEach { optionData in
            predictionWidgetView.addOption(withID: optionData.id) { optionView in
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
                optionView.delegate = self
                self.applyOptionTheme(
                    optionView: optionView,
                    optionTheme: theme.widgets.prediction.unselectedOption
                )
            }
        }
        self.applyTheme(theme)
        self.model.delegate = self
        self.model.registerImpression()
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
        self.closeButtonAction = { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
        predictionWidgetView.titleView.showCloseButton()
    }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        predictionWidgetView.titleView.beginTimer(
            duration: model.interactionTimeInterval,
            animationFilepath: theme.lottieFilepaths.timer
        ) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }

    private func enterInteractingState(){
        self.predictionWidgetView.isUserInteractionEnabled = true
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        if let firstTapTime = self.firstTapTime, let lastTapTime = self.timeOfLastInteraction {
            self.model.eventRecorder.record(
                .widgetInteracted(
                    properties: WidgetInteractedProperties(
                        widgetId: self.model.id,
                        widgetKind: self.model.kind.analyticsName,
                        firstTapTime: firstTapTime,
                        lastTapTime: lastTapTime,
                        numberOfTaps: self.interactionCount
                    )
                )
            )
        }
        self.predictionWidgetView.coreWidgetView.contentView?.isUserInteractionEnabled = false
        self.interactableState = .closedToInteraction
         
        guard let selectedOption = self.currentSelection else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }
                        
        guard let selectionWidgetData = self.model.options.first(where: { $0.id == selectedOption.id}) else {
            log.error("Couldn't find widget data for option with id \(selectedOption.id)")
            return
        }

        self.model.lockInVote(optionID: selectionWidgetData.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.canShowResults = true
                log.debug("Successfully submitted prediction.")

                let totalVotes = self.model.options.map{ $0.voteCount }.reduce(0, +)
                if totalVotes > 0 {
                    self.predictionWidgetView.options.forEach { option in
                        guard let optionResult = self.model.options.first(where: { $0.id == option.id }) else { return }
                        let progress: CGFloat = CGFloat(optionResult.voteCount) / CGFloat(totalVotes)
                        option.setProgress(progress)
                    }
                }

                if let animationFilepath = self.theme.lottieFilepaths.predictionTimerComplete.randomElement() {
                    self.predictionWidgetView.playOverlayAnimation(animationFilepath: animationFilepath) {
                        self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                    }
                }
            case .failure(let error):
                log.error("Error: \(error.localizedDescription)")
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        }
    }
    
    private func enterFinishedState() {
        predictionWidgetView.stopOverlayAnimation()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
    
    @objc private func onCloseButtonPressed() {
        self.closeButtonAction?()
    }
    
    private func applyTheme(_ theme: Theme) {
        predictionWidgetView.titleView.titleMargins = theme.choiceWidgetTitleMargins
        predictionWidgetView.applyContainerProperties(theme.widgets.prediction.main)
        predictionWidgetView.titleView.applyContainerProperties(theme.widgets.prediction.header)
        predictionWidgetView.bodyBackground = theme.widgets.prediction.body.background
        predictionWidgetView.titleView.titleLabel.textColor = theme.widgets.prediction.title.color
        predictionWidgetView.titleView.titleLabel.font = theme.widgets.prediction.title.font
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
        optionView.barCornerRadii = optionTheme.progressBar.cornerRadii
        optionView.percentageFont = optionTheme.percentage.font
        optionView.percentageTextColor = optionTheme.percentage.color
    }
}

extension PredictionWidgetViewController: PredictionWidgetModelDelegate {
    func predictionWidgetModel(_ model: PredictionWidgetModel, voteCountDidChange voteCount: Int, forOption optionID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let option = self.predictionWidgetView.options.first(where: { $0.id == optionID }) else { return }

            if self.canShowResults {
                let totalVotes = self.model.options.map{ $0.voteCount }.reduce(0, +)
                guard totalVotes > 0 else { return }
                let progress: CGFloat = CGFloat(voteCount) / CGFloat(totalVotes)
                option.setProgress(progress)
            }
        }
    }
}

extension PredictionWidgetViewController: ChoiceWidgetOptionDelegate {
    func wasSelected(_ option: ChoiceWidgetOption) {

        // Ignore repeated selections
        guard currentSelection?.id != option.id else { return }

        self.userDidInteract = true
        currentSelection = option

        for optionButton in predictionWidgetView.options {
            optionButton.optionThemeStyle = .unselected
            self.applyOptionTheme(
                optionView: optionButton,
                optionTheme: theme.widgets.prediction.unselectedOption
            )
        }
        option.optionThemeStyle = .selected
        self.applyOptionTheme(
            optionView: option,
            optionTheme: theme.widgets.prediction.selectedOption
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
