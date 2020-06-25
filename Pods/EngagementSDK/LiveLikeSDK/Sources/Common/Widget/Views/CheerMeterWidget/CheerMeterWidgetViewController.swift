//
//  CheerMeterWidgetViewController.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/10/19.
//

import Lottie
import UIKit

class CheerMeterWidgetViewController: WidgetController {
    
    // WidgetViewModel conformance
    var id: String
    var kind: WidgetKind
    let interactionTimeInterval: TimeInterval?
    weak var delegate: WidgetEvents?

    var dismissSwipeableView: UIView {
        return self.view
    }
    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var userDidInteract: Bool = false
    var customData: String?
    var previousState: WidgetState?
    var currentState: WidgetState = .ready {
        willSet {
            previousState = self.currentState
        }
        didSet {
            self.delegate?.widgetDidEnterState(widget: self, state: currentState)
            switch currentState {
            case .ready:
                break
            case .interacting:
                enterInteractionState()
            case .results:
                enterResultsState()
            case .finished:
                enterFinishedState()
            }
        }
    }

    private let tutorialDuration: TimeInterval = 5.0
    private let tapGameDuration: TimeInterval = 10.0

    private lazy var cheerMeter = CheerMeterWidgetView(theme: self.theme)
    private let cheerMeterResults: ResultsView
    private let cheerMeterData: CheerMeterCreated
    private let leftCheerOption: CheerOption
    private let rightCheerOption: CheerOption
    private let leftVoteClient: CheerMeterVoteClient
    private let rightVoteClient: CheerMeterVoteClient
    private let resultsClient: CheerMeterResultsClient
    private let theme: Theme
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository

    private var leftScore: Int = 0
    private var rightScore: Int = 0
    private var myScore: Int = 0

    // Analytics
    var eventRecorder: EventRecorder
    private var timeCreated: Date = Date()
    private var firstTapTime: Date?
    private var lastTapTime: Date?
    private var interactableState: InteractableState = .closedToInteraction

    init(
        cheerMeterData: CheerMeterCreated,
        leftVoteClient: CheerMeterVoteClient,
        rightVoteClient: CheerMeterVoteClient,
        resultsClient: CheerMeterResultsClient,
        theme: Theme,
        eventRecorder: EventRecorder
    ) throws {
        guard cheerMeterData.options.count == 2 else {
            throw InitializationError.unexpectedNumberOfOptions(inEvent: cheerMeterData)
        }

        self.cheerMeterData = cheerMeterData
        self.cheerMeterResults = ResultsView(theme: theme)
        leftCheerOption = cheerMeterData.options[0]
        rightCheerOption = cheerMeterData.options[1]
        id = cheerMeterData.id
        kind = cheerMeterData.kind
        self.leftVoteClient = leftVoteClient
        self.rightVoteClient = rightVoteClient
        self.resultsClient = resultsClient
        self.theme = theme
        self.eventRecorder = eventRecorder
        self.widgetTitle = cheerMeterData.question
        self.options = Set(cheerMeterData.options.map({ WidgetOption(id: $0.id, text: $0.description, image: nil)}))
        self.interactionTimeInterval = cheerMeterData.timeout.timeInterval
        self.customData = cheerMeterData.customData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startTapGame() {

    }
}

// MARK: - Enums

private extension CheerMeterWidgetViewController {
    enum Side {
        case left
        case right
    }
}

// MARK: - View Lifecycle

extension CheerMeterWidgetViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cheerMeter.translatesAutoresizingMaskIntoConstraints = false
        cheerMeterResults.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cheerMeter)
        view.addSubview(cheerMeterResults)
        
        cheerMeter.constraintsFill(to: view)
        NSLayoutConstraint.activate([
            cheerMeterResults.topAnchor.constraint(equalTo: cheerMeter.topAnchor),
            cheerMeterResults.leadingAnchor.constraint(equalTo: cheerMeter.leadingAnchor),
            cheerMeterResults.trailingAnchor.constraint(equalTo: cheerMeter.trailingAnchor),
            cheerMeterResults.heightAnchor.constraint(equalToConstant: 200)
        ])
        cheerMeterResults.constraintsFill(to: cheerMeter)
        
        cheerMeter.setLeftCircleFeedbackProperties(
            fillColor: theme.cheerMeter.teamOneLeftColor.withAlphaComponent(0.4),
            strokeColor: theme.cheerMeter.teamOneRightColor.withAlphaComponent(0.6)
        )
        cheerMeter.setRightCircleFeedbackProperties(
            fillColor: theme.cheerMeter.teamTwoLeftColor.withAlphaComponent(0.4),
            strokeColor: theme.cheerMeter.teamTwoRightColor.withAlphaComponent(0.6)
        )
        
        cheerMeter.setup(question: cheerMeterData.question,
                         duration: cheerMeterData.timeout.timeInterval,
                         leftChoice: leftCheerOption,
                         rightChoice: rightCheerOption,
                         mediaRepository: mediaRepository,
                         theme: theme)
        cheerMeter.delegate = self
        resultsClient.delegate = self

        cheerMeterResults.isUserInteractionEnabled = false
        
        eventRecorder.record(.widgetDisplayed(kind: kind.stringValue, widgetId: cheerMeterData.id))
        
        cheerMeter.isUserInteractionEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

extension CheerMeterWidgetViewController: CheerMeterWidgetViewDelegate {
    func optionSelected(button: CheerMeterWidgetViewButtons) {
        handleTapGamePress(button: button)
    }

    private func handleTapGamePress(button: CheerMeterWidgetViewButtons) {
        if myScore == 0 {
            // Fade out versus animation if first tap
            cheerMeter.fadeOutVersusAnimation()
        }
        
        myScore += 1
        cheerMeter.score = myScore.description

        switch button {
        case .leftChoice:
            cheerMeter.flashLeftPowerBar()
            cheerMeter.playLeftScoreAnimation()
            leftVoteClient.sendVote()
        case .rightChoice:
            cheerMeter.flashRightPowerBar()
            cheerMeter.playRightScoreAnimation()
            rightVoteClient.sendVote()
        }
        
        cheerMeter.scoreLabelFadeInOut()

        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        lastTapTime = now
    }
}

// MARK: - CheerMeterVoteClientDelegate

extension CheerMeterWidgetViewController: CheerMeterResultsDelegate {
    func didReceiveResults(_ results: CheerMeterResults) {
        guard currentState != .results else {
            return
        }
        
        if let leftResults = results.options.first(where: { $0.id == leftCheerOption.id }) {
            leftScore = leftResults.voteCount
            cheerMeter.leftChoiceScore = leftResults.voteCount
        }
        if let rightResults = results.options.first(where: { $0.id == rightCheerOption.id }) {
            rightScore = rightResults.voteCount
            cheerMeter.rightChoiceScore = rightResults.voteCount
        }
    }
}

// MARK: - Internal APIs

internal extension CheerMeterWidgetViewController {
    
    func moveToNextState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
    }
    
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        // Not implemented
    }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        cheerMeter.timerDuration = CGFloat(seconds)
        cheerMeter.playTimerAnimation { [weak self] _ in
            guard let self = self else { return }
            completion(self)
        }
    }

    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            var widgetDismissedProperties = WidgetDismissedProperties(widgetId: cheerMeterData.id,
                                                                      widgetKind: kind.stringValue,
                                                                      dismissAction: dismissAction,
                                                                      numberOfTaps: myScore,
                                                                      dismissSecondsSinceStart: Date().timeIntervalSince(timeCreated))
            if let lastTapTime = self.lastTapTime {
                widgetDismissedProperties.dismissSecondsSinceLastTap = Date().timeIntervalSince(lastTapTime)
            }
            widgetDismissedProperties.interactableState = interactableState
            eventRecorder.record(.widgetUserDismissed(properties: widgetDismissedProperties))
        }
    }

    enum InitializationError: Swift.Error {
        case unexpectedNumberOfOptions(inEvent: CheerMeterCreated)
    }
}

// MARK: - Private APIs

private extension CheerMeterWidgetViewController {
    
    private func enterInteractionState() {
        cheerMeter.playVersusAnimation()
        interactableState = .openToInteraction
        cheerMeter.showScores()
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
        cheerMeter.isUserInteractionEnabled = true
    }
    
    private func enterResultsState() {
        interactableState = .closedToInteraction
        cheerMeter.isUserInteractionEnabled = false
        
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
                    return self.cheerMeter.leftChoiceImage
                } else {
                    return self.cheerMeter.rightChoiceImage
                }
            }()
            
            guard let winnersImage = winnerImage else {
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                return
            }
            
            self.cheerMeterResults.playWin(winnerImage: winnersImage) { [weak self] in
                guard let self = self else { return }
                self.resultsClient.delegate = nil
                
                let properties = WidgetInteractedProperties(
                    widgetId: self.cheerMeterData.id,
                    widgetKind: self.kind.analyticsName,
                    firstTapTime: self.firstTapTime,
                    lastTapTime: self.lastTapTime,
                    numberOfTaps: self.myScore,
                    interactionTimeInterval: self.interactionTimeInterval,
                    widgetViewModel: self,
                    previousState: .interacting,
                    currentState: .results
                )
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        }
    }
    
    private func enterFinishedState() {
        let properties = WidgetInteractedProperties(
            widgetId: self.cheerMeterData.id,
            widgetKind: self.kind.analyticsName,
            firstTapTime: self.firstTapTime,
            lastTapTime: self.lastTapTime,
            numberOfTaps: self.myScore,
            interactionTimeInterval: self.interactionTimeInterval,
            widgetViewModel: self,
            previousState: previousState ?? .interacting,
            currentState: .finished
        )
        self.cheerMeter.animateFinishedState()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
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
            let lottie = AnimationView(filePath: theme.randomTieAnimationFilepath())
            lottie.contentMode = .scaleAspectFit

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
            let lottie = AnimationView(filePath: theme.randomIncorrectAnimationAsset())
            lottie.contentMode = .scaleAspectFit

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

        func playWin(winnerImage: UIImage, completion: @escaping () -> Void) {
            let lottie = AnimationView(filePath: theme.cheerMeter.filepathForWinnerLottieAnimation)
            let winnerImageView = UIImageView(image: winnerImage)
            winnerImageView.contentMode = .scaleAspectFit
            
            addSubview(winnerImageView)
            addSubview(lottie)
            
            lottie.contentMode = .scaleAspectFit
            
            winnerImageView.constraintsFill(to: self)
            lottie.constraintsFill(to: self)
            
            winnerImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
            UIView.animate(withDuration: 1, animations: {
                winnerImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            })

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
        leftChoice: CheerOption,
        rightChoice: CheerOption,
        mediaRepository: MediaRepository,
        theme: Theme
    ) {
        titleText = question
        leftChoiceText = leftChoice.description
        rightChoiceText = rightChoice.description
        timerDuration = CGFloat(duration)
        instructionText = "EngagementSDK.widget.CheerMeter.instruction".localized(withComment: "Text to teach user how to play the game by tapping.")

        mediaRepository.getImage(url: leftChoice.imageUrl) { [weak self] result in
            switch result {
            case .success(let success):
                self?.leftChoiceImage = success.image
            case .failure(let error):
                log.error(error)
            }
        }
        
        mediaRepository.getImage(url: rightChoice.imageUrl) { [weak self] result in
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
