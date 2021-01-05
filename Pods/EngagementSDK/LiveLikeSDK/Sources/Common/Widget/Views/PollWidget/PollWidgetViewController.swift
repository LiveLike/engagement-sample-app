//
//  File.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/14/19.
//

import UIKit

class PollWidgetViewController: Widget {

    // MARK: Internal Properties
    override var theme: Theme {
        didSet {
            self.applyTheme(theme)
            
            self.widgetView.options.forEach { optionView in
                switch optionView.optionThemeStyle {
                case .selected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.poll.selectedOption
                    )
                case .unselected:
                    self.applyOptionTheme(
                        optionView: optionView,
                        optionTheme: theme.widgets.poll.unselectedOption
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
    
    private var firstTapTime: Date?
    private var myPollSelection: WidgetOption?
    private let optionType: ChoiceWidgetOptionButton.Type
    private lazy var widgetView: ChoiceWidget = {
        let view = VerticalChoiceWidget(optionType: self.optionType)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository
    private let model: PollWidgetModel
    
    override init(model: PollWidgetModel) {
        self.model = model
        self.optionType = model.containsImages ? WideTextImageChoice.self : TextChoiceWidgetOptionButton.self
        super.init(model: model)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: Lifecycle Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        widgetView.isUserInteractionEnabled = false
        view.addSubview(widgetView)
        widgetView.constraintsFill(to: view)

        widgetView.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        widgetView.titleView.titleLabel.text = widgetTitle
        self.optionsArray?.forEach { optionData in
            self.widgetView.addOption(withID: optionData.id) { optionView in
                optionView.text = optionData.text
                if let imageUrl = optionData.imageUrl {
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
                    optionTheme: theme.widgets.poll.unselectedOption
                )
            }
        }
        applyTheme(theme)
        
        self.model.delegate = self
        self.model.registerImpression()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: UI Functionality

    private var closeButtonCompletion: ((WidgetViewModel) -> Void)?
    
    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        self.widgetView.titleView.showCloseButton()
        closeButtonCompletion = completion
    }
    
    @objc private func closeButtonPressed() {
        closeButtonCompletion?(self)
    }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        self.widgetView.titleView.beginTimer(
            duration: seconds,
            animationFilepath: theme.lottieFilepaths.timer
        ) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }
    
    private func applyTheme(_ theme: Theme) {
        widgetView.applyContainerProperties(theme.widgets.poll.main)
        widgetView.titleView.titleMargins = theme.choiceWidgetTitleMargins
        widgetView.bodyBackground = .fill(color: theme.widgetBodyColor)
        widgetView.optionSpacing = theme.interOptionSpacing
        widgetView.headerBodySpacing = theme.titleBodySpacing
        widgetView.titleView.titleLabel.textColor = theme.widgets.poll.title.color
        widgetView.titleView.titleLabel.font = theme.widgets.poll.title.font
        widgetView.titleView.applyContainerProperties(theme.widgets.poll.header)
    }

    private func applyOptionTheme(
        optionView: ChoiceWidgetOption,
        optionTheme: Theme.ChoiceWidget.Option
    ) {
        optionView.descriptionTextColor = optionTheme.description.color
        optionView.descriptionFont = optionTheme.description.font
        optionView.barBackground = optionTheme.progressBar.background
        optionView.barCornerRadii = optionTheme.progressBar.cornerRadii
        optionView.percentageFont = optionTheme.percentage.font
        optionView.percentageTextColor = optionTheme.percentage.color
        optionView.applyContainerProperties(optionTheme.container)
    }
    
    // MARK: Results

    /// Shows results from `WidgetOption` data that already exists
    private func showResultsFromWidgetOptions() {
        
        guard let pollOptions = options else { return }
        let totalVoteCount = pollOptions.map { $0.voteCount ?? 0 }.reduce(0, +)
      
        for optionButton in widgetView.options {
            for updateOption in pollOptions where optionButton.id == updateOption.id {
                let votePercentage: CGFloat = totalVoteCount > 0 ? CGFloat(updateOption.voteCount!) / CGFloat(totalVoteCount) : 0
                                
                if votePercentage > 0.0 {
                    self.applyOptionTheme(
                        optionView: optionButton,
                        optionTheme: theme.widgets.poll.selectedOption
                    )
                    optionButton.borderWidth = 0.0
                }
                optionButton.setProgress(votePercentage)
            }
        }
    }

    // MARK: Widget States
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
    
    private func enterInteractingState() {
        widgetView.isUserInteractionEnabled = true
        self.interactableState = .openToInteraction
        self.widgetView.options.forEach {
            $0.isUserInteractionEnabled = true
        }
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        if myPollSelection == nil {
            showResultsFromWidgetOptions()
        }
        
        widgetView.isUserInteractionEnabled = false
        self.interactableState = .closedToInteraction
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
        self.widgetView.options.forEach {
            $0.isUserInteractionEnabled = false
        }

        self.delegate?.widgetStateCanComplete(widget: self, state: .results)
    }
    
    private func enterFinishedState() {
        
        // Display results from `WidgetOptions` if entering `finished` state without casting a vote
        if myPollSelection == nil {
            showResultsFromWidgetOptions()
        }
        
        widgetView.isUserInteractionEnabled = false
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}

extension PollWidgetViewController: ChoiceWidgetOptionDelegate {
    func wasSelected(_ option: ChoiceWidgetOption) {
      
        guard let widgetOption = self.options?.first(where: { $0.id == option.id }) else {
            return
        }
        myPollSelection = widgetOption
        self.userDidInteract = true
        
        // unselect all
        widgetView.options.forEach { optionView in
            optionView.optionThemeStyle = .unselected
            self.applyOptionTheme(
                optionView: optionView,
                optionTheme: theme.widgets.poll.unselectedOption
            )
        }
        
        // select selection
        option.optionThemeStyle = .selected
        self.applyOptionTheme(
            optionView: option,
            optionTheme: theme.widgets.poll.selectedOption
        )

        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        timeOfLastInteraction = now
        interactionCount += 1
        model.submitVote(optionID: option.id)
        self.delegate?.userDidInteract(self)
    }
    
    func wasDeselected(_ option: ChoiceWidgetOption) {}
}

// MARK: - Receiving a vote
extension PollWidgetViewController: PollWidgetModelDelegate {
    func pollWidgetModel(_ model: PollWidgetModel, voteCountDidChange answerCount: Int, forOption optionID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let optionButton = self.widgetView.options.first(where: { $0.id == optionID }) else { return }
           
            let totalVotes = model.options.map { $0.voteCount }.reduce(0, +)
            guard totalVotes > 0 else { return }
            optionButton.setProgress(CGFloat(answerCount) / CGFloat(totalVotes))
        }
    }
}
