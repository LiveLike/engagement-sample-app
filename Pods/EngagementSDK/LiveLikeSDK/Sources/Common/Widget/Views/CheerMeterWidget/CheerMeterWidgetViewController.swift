//
//  CheerMeterWidgetViewController.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/10/19.
//

import Lottie
import UIKit

class CheerMeterWidgetViewController: Widget {

    enum InitializationError: Swift.Error {
        case unexpectedNumberOfOptions(inEvent: CheerMeterWidgetModel)
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
                    self.enterInteractionState()
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }

    private lazy var cheerMeterView = CheerMeterWidgetView(theme: self.theme)
    private lazy var cheerMeterResults = ResultsView(theme: self.theme)
    
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository
    private var eventRecorder: EventRecorder {
        return model.eventRecorder
    }
    private let model: CheerMeterWidgetModel
    
    private var leftCheerOption: CheerMeterWidgetModel.Option
    private var rightCheerOption: CheerMeterWidgetModel.Option

    private var localLeftVoteCount: Int = 0
    private var localRightVoteCount: Int = 0
    private var leftScore: Int = 0
    private var rightScore: Int = 0
    private var myScore: Int = 0
    private var firstTapTime: Date?

    init(
        model: CheerMeterWidgetModel,
        firstOption: CheerMeterWidgetModel.Option,
        secondOption: CheerMeterWidgetModel.Option
    ) {
        self.model = model
        self.leftCheerOption = firstOption
        self.rightCheerOption = secondOption
        
        super.init(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func moveToNextState() {
        switch self.currentState {
        case .ready :
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
        // Not implemented
    }

    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        cheerMeterView.timerDuration = CGFloat(seconds)
        cheerMeterView.playTimerAnimation { [weak self] _ in
            guard let self = self else { return }
            completion(self)
        }
    }
}

// MARK: - View Lifecycle

extension CheerMeterWidgetViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cheerMeterView.translatesAutoresizingMaskIntoConstraints = false
        cheerMeterResults.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cheerMeterView)
        view.addSubview(cheerMeterResults)
        
        cheerMeterView.constraintsFill(to: view)
        NSLayoutConstraint.activate([
            cheerMeterResults.topAnchor.constraint(equalTo: cheerMeterView.topAnchor),
            cheerMeterResults.leadingAnchor.constraint(equalTo: cheerMeterView.leadingAnchor),
            cheerMeterResults.trailingAnchor.constraint(equalTo: cheerMeterView.trailingAnchor),
            cheerMeterResults.heightAnchor.constraint(equalToConstant: 200)
        ])
        cheerMeterResults.constraintsFill(to: cheerMeterView)
        
        cheerMeterView.setLeftCircleFeedbackProperties(
            fillColor: theme.cheerMeter.teamOneLeftColor.withAlphaComponent(0.4),
            strokeColor: theme.cheerMeter.teamOneRightColor.withAlphaComponent(0.6)
        )
        cheerMeterView.setRightCircleFeedbackProperties(
            fillColor: theme.cheerMeter.teamTwoLeftColor.withAlphaComponent(0.4),
            strokeColor: theme.cheerMeter.teamTwoRightColor.withAlphaComponent(0.6)
        )
        
        cheerMeterView.setup(question: model.title,
                         duration: model.interactionTimeInterval,
                         leftChoice: leftCheerOption,
                         rightChoice: rightCheerOption,
                         mediaRepository: mediaRepository,
                         theme: theme)
        cheerMeterView.delegate = self
        model.delegate = self

        cheerMeterResults.isUserInteractionEnabled = false
        
        cheerMeterView.isUserInteractionEnabled = false

        model.registerImpression()
    }
}

extension CheerMeterWidgetViewController: CheerMeterWidgetModelDelegate {
    
    func cheerMeterWidgetModel(_ model: CheerMeterWidgetModel, voteCountDidChange voteCount: Int, forOption optionID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.currentState != .results else {
                return
            }
            
            if optionID == self.leftCheerOption.id {
                self.leftScore = voteCount
                self.cheerMeterView.leftChoiceScore = voteCount
            } else if optionID == self.rightCheerOption.id {
                self.rightScore = voteCount
                self.cheerMeterView.rightChoiceScore = voteCount
            }
        }
    }
    
    func cheerMeterWidgetModel(_ model: CheerMeterWidgetModel, voteRequest: CheerMeterWidgetModel.VoteRequest, didComplete result: Result<CheerMeterWidgetModel.Vote, Error>) { }
}

extension CheerMeterWidgetViewController: CheerMeterWidgetViewDelegate {
    func optionSelected(button: CheerMeterWidgetViewButtons) {
        handleTapGamePress(button: button)
    }

    private func handleTapGamePress(button: CheerMeterWidgetViewButtons) {
        if myScore == 0 {
            // Fade out versus animation if first tap
            cheerMeterView.fadeOutVersusAnimation()
        }
        
        myScore += 1
        cheerMeterView.score = myScore.description

        switch button {
        case .leftChoice:
            cheerMeterView.flashLeftPowerBar()
            cheerMeterView.playLeftScoreAnimation()
            localLeftVoteCount += 1
            model.submitVote(optionID: leftCheerOption.id)
        case .rightChoice:
            cheerMeterView.flashRightPowerBar()
            cheerMeterView.playRightScoreAnimation()
            localRightVoteCount += 1
            model.submitVote(optionID: rightCheerOption.id)
        }
        
        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        timeOfLastInteraction = now
        interactionCount += 1
        
        cheerMeterView.scoreLabelFadeInOut()
        self.delegate?.userDidInteract(self)
    }
}

// MARK: - Private APIs

private extension CheerMeterWidgetViewController {
    
    private func enterInteractionState() {
        cheerMeterView.playVersusAnimation()
        interactableState = .openToInteraction
        self.model.markAsInteractive()
        userDidInteract = true
        cheerMeterView.showScores()
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
        cheerMeterView.isUserInteractionEnabled = true
    }
    
    private func enterResultsState() {
        interactableState = .closedToInteraction
        cheerMeterView.isUserInteractionEnabled = false
        if let firstTapTime = firstTapTime, let lastTapTime = timeOfLastInteraction {
            let props = WidgetInteractedProperties(
                widgetId: model.id,
                widgetKind: model.kind.analyticsName,
                firstTapTime: firstTapTime,
                lastTapTime: lastTapTime,
                numberOfTaps: interactionCount
            )
            eventRecorder.record(.widgetInteracted(programID: model.programID, properties: props))
        }

        // If the user did not interact, display stale results from backend
        guard userDidInteract else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            showResultsFromWidgetOptions()
            return
        }
        
        // Handle the possibility of backend not posting results fast enough
        if leftScore == 0 && rightScore == 0 {
            leftScore = localLeftVoteCount
            cheerMeterView.leftChoiceScore = localLeftVoteCount
            
            rightScore = localRightVoteCount
            cheerMeterView.rightChoiceScore = localRightVoteCount
        }
        
        // handle tie
        if leftScore == rightScore {
            self.cheerMeterResults.playTieAnimation {
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                return
            }
        } else {
            // handle a winner
            let winnerImage: UIImage? = {
                if leftScore > rightScore {
                    return self.cheerMeterView.leftChoiceImage
                } else {
                    return self.cheerMeterView.rightChoiceImage
                }
            }()
            
            guard let winnersImage = winnerImage else {
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                return
            }
            
            self.cheerMeterResults.playWin(winnerImage: winnersImage, animated: true) { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        }
    }
    
    private func enterFinishedState() {
        interactableState = .closedToInteraction
        cheerMeterView.isUserInteractionEnabled = false
        
        if userDidInteract == false {
            showResultsFromWidgetOptions()
        }
        
        self.cheerMeterView.animateFinishedState()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
    
    /// Shows results from `WidgetOption` data that already exists
    private func showResultsFromWidgetOptions() {
        
        guard let cheerResults = options else { return }
        
        cheerMeterView.showScores()
        
        if let leftResults = cheerResults.first(where: { $0.id == leftCheerOption.id }) {
            leftScore = leftResults.voteCount ?? 0
            cheerMeterView.leftChoiceScore = leftResults.voteCount ?? 0
        }
        if let rightResults = cheerResults.first(where: { $0.id == rightCheerOption.id }) {
            rightScore = rightResults.voteCount ?? 0
            cheerMeterView.rightChoiceScore = rightResults.voteCount ?? 0
        }
        
        // handle tie
        if leftScore == rightScore {
            self.cheerMeterResults.playTieAnimation {
                return
            }
        } else {
            // handle a winner
            let winnerImageURL: URL? = {
                if leftScore > rightScore {
                    return self.cheerMeterView.leftChoiceImageURL
                } else {
                    return self.cheerMeterView.rightChoiceImageURL
                }
            }()
            
            if let winnerImageURL = winnerImageURL {
                mediaRepository.getImage(url: winnerImageURL) { [weak self] result in
                    switch result {
                    case .success(let success):
                        self?.cheerMeterResults.playWin(winnerImage: success.image, animated: false) {}
                    case .failure(let error):
                        log.error(error)
                    }
                }
            }
        }
    }
    
    class ResultsView: UIView {
        private let theme: Theme

        init(theme: Theme){
            self.theme = theme
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func playTieAnimation(completion: @escaping () -> Void) {
            let lottie = AnimationView(filePath: theme.lottieFilepaths.randomTie())
            lottie.contentMode = .scaleAspectFit
            lottie.backgroundBehavior = .pauseAndRestore

            addSubview(lottie)
            lottie.constraintsFill(to: self)

            lottie.play { complete in
                if complete {
                    UIView.animate(withDuration: 0.2, animations: {
                        lottie.alpha = 0
                    }, completion: { _ in
                        completion()
                    })
                }
            }
            
        }

        func playLose(completion: @escaping () -> Void) {
            let lottie = AnimationView(filePath: theme.lottieFilepaths.randomLose())
            lottie.contentMode = .scaleAspectFit
            lottie.backgroundBehavior = .pauseAndRestore

            addSubview(lottie)
            lottie.constraintsFill(to: self)

            lottie.play { complete in
                if complete {
                    UIView.animate(withDuration: 0.2, animations: {
                        lottie.alpha = 0
                    }, completion: { _ in
                        completion()
                    })
                }
            }
        }

        func playWin(winnerImage: UIImage, animated: Bool, completion: @escaping () -> Void) {
            let lottie = AnimationView(filePath: theme.cheerMeter.filepathForWinnerLottieAnimation)
            let winnerImageView = UIImageView(image: winnerImage)
            winnerImageView.contentMode = .scaleAspectFit
            
            addSubview(winnerImageView)
            addSubview(lottie)
            
            lottie.contentMode = .scaleAspectFit
            lottie.backgroundBehavior = .pauseAndRestore
            
            winnerImageView.constraintsFill(to: self)
            lottie.constraintsFill(to: self)
            
            winnerImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
            UIView.animate(withDuration: animated ? 1 : 0, animations: {
                winnerImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            })
            lottie.animationSpeed = animated ? 1 : 0
            lottie.play { complete in
                if complete {
                    completion()
                }
            }
        }
    }
}

// MARK: - CheerMeterWidgetView setup from model

private extension CheerMeterWidgetView {
    func setup(
        question: String,
        duration: TimeInterval,
        leftChoice: CheerMeterWidgetModel.Option,
        rightChoice: CheerMeterWidgetModel.Option,
        mediaRepository: MediaRepository,
        theme: Theme
    ) {
        titleText = question
        leftChoiceText = leftChoice.text
        rightChoiceText = rightChoice.text
        timerDuration = CGFloat(duration)
        instructionText = "EngagementSDK.widget.CheerMeter.instruction".localized(comment: "Text to teach user how to play the game by tapping.")
        leftChoiceImageURL = leftChoice.imageURL
        rightChoiceImageURL = rightChoice.imageURL

        mediaRepository.getImage(url: leftChoice.imageURL) { [weak self] result in
            switch result {
            case .success(let success):
                self?.leftChoiceImage = success.image
            case .failure(let error):
                log.error(error)
            }
        }
        
        mediaRepository.getImage(url: rightChoice.imageURL) { [weak self] result in
            switch result {
            case .success(let success):
                self?.rightChoiceImage = success.image
            case .failure(let error):
                log.error(error)
            }
        }

        applyTheme(theme)
    }
}
