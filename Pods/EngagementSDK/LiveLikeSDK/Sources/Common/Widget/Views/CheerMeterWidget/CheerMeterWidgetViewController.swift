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
    weak var delegate: WidgetEvents?

    var dismissSwipeableView: UIView {
        return self.view
    }

    private let tutorialDuration: TimeInterval = 5.0
    private let tapGameDuration: TimeInterval = 10.0

    private let cheerMeter = CheerMeterWidgetView()
    private let cheerMeterResults: ResultsView
    private let cheerMeterData: CheerMeterCreated
    private let leftCheerOption: CheerOption
    private let rightCheerOption: CheerOption
    private let voteClient: CheerMeterVoteClient
    private let theme: Theme
    private let cache: Cache = Cache.shared

    private var mySide: Side?
    private var state: CheerMeterState {
        didSet {
            switch state {
            case .sideSelection: startSideSelection()
            case .tutorial: startTutorial()
            case .tapGame: startTapGame()
            case .results: startResults()
            }
        }
    }

    private var leftScore: Int = 0
    private var rightScore: Int = 0
    private var myScore: Int = 0

    // Analytics
    var eventRecorder: EventRecorder
    private var timeCreated: Date = Date()
    private var firstTapTime: Date?
    private var lastTapTime: Date?
    private var interactableState: InteractableState = .closedToInteraction

    init(cheerMeterData: CheerMeterCreated, voteClient: CheerMeterVoteClient, theme: Theme, eventRecorder: EventRecorder) throws {
        guard cheerMeterData.options.count == 2 else {
            throw InitializationError.unexpectedNumberOfOptions(inEvent: cheerMeterData)
        }

        self.cheerMeterData = cheerMeterData
        self.cheerMeterResults = ResultsView(theme: theme)
        leftCheerOption = cheerMeterData.options[0]
        rightCheerOption = cheerMeterData.options[1]
        id = cheerMeterData.id
        kind = cheerMeterData.kind
        self.voteClient = voteClient
        self.theme = theme
        self.eventRecorder = eventRecorder
        state = .sideSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startSideSelection() {
        interactableState = .openToInteraction
        cheerMeter.playVersusAnimation()
        cheerMeter.playTimerAnimation { [weak self] finished in
            guard let self = self, finished else { return }
            // If state hasn't changed then dismiss early
            if self.state == .sideSelection {
                self.delegate?.actionHandler(event: .dismiss(action: .timeout))
            }
        }
    }

    private func startTutorial() {
        interactableState = .closedToInteraction
        if let mySide = mySide {
            switch mySide {
            case .left:
                cheerMeter.setCircleFeedbackProperties(fillColor: UIColor(red: 80, green: 160, blue: 250, alpha: 0.4),
                                                       strokeColor: UIColor(red: 80, green: 160, blue: 250, alpha: 0.6))
            case .right:
                cheerMeter.setCircleFeedbackProperties(fillColor: UIColor(red: 250, green: 80, blue: 100, alpha: 0.4),
                                                       strokeColor: UIColor(red: 250, green: 80, blue: 100, alpha: 0.6))
            }
        }

        cheerMeter.playTutorialAnimation(duration: 4) {
            self.state = .tapGame
        }
    }

    private func startTapGame() {
        interactableState = .openToInteraction
        cheerMeter.showScores()
        cheerMeter.timerDuration = CGFloat(tapGameDuration)
        cheerMeter.playTimerAnimation { [weak self] finished in
            guard let self = self, finished else { return }
            self.cheerMeter.playTapGameOverAnimation {
                self.state = .results
            }
        }
    }

    private func startResults() {
        interactableState = .closedToInteraction
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.voteClient.removeDelegate(self)
            
            if let firstTapTime = self.firstTapTime, let lastTapTime = self.lastTapTime {
                let properties = WidgetInteractedProperties(widgetId: self.cheerMeterData.id,
                                                            widgetKind: self.kind.analyticsName,
                                                            firstTapTime: firstTapTime,
                                                            lastTapTime: lastTapTime,
                                                            numberOfTaps: self.myScore)
                self.delegate?.widgetInteractionDidComplete(properties: properties)
            }
            guard let mySide = self.mySide else { return }
            let winner: Side = self.leftScore > self.rightScore ? .left : .right
            if winner == mySide {
                if let winnerImage = mySide == .left ? self.cheerMeter.leftChoiceImage : self.cheerMeter.rightChoiceImage {
                    self.cheerMeterResults.playWin(winnerImage: winnerImage, completion: {
                        self.delegate?.actionHandler(event: .dismiss(action: .timeout))
                    })
                }
            } else {
                self.cheerMeterResults.playLose {
                    self.delegate?.actionHandler(event: .dismiss(action: .timeout))
                }
            }
        }
    }
}

// MARK: - Enums

private extension CheerMeterWidgetViewController {
    enum Side {
        case left
        case right
    }

    enum CheerMeterState {
        case sideSelection
        case tutorial
        case tapGame
        case results
    }
}

// MARK: - View Lifecycle

extension CheerMeterWidgetViewController {
    override func loadView() {
        view = cheerMeter
        view.addSubview(cheerMeterResults)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cheerMeter.setup(question: cheerMeterData.question,
                         duration: cheerMeterData.timeout.timeInterval,
                         leftChoice: leftCheerOption,
                         rightChoice: rightCheerOption,
                         cache: cache,
                         theme: theme)
        cheerMeter.delegate = self
        voteClient.setDelegate(self)

        cheerMeterResults.isUserInteractionEnabled = false
        cheerMeterResults.constraintsFill(to: view)

        eventRecorder.record(.widgetDisplayed(kind: kind.stringValue, widgetId: cheerMeterData.id))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        voteClient.removeDelegate(self)
    }
}

extension CheerMeterWidgetViewController: CheerMeterWidgetViewDelegate {
    func optionSelected(button: CheerMeterWidgetViewButtons) {
        switch state {
        case .sideSelection: handleSideSelectionPress(button: button)
        case .tutorial: break
        case .tapGame: handleTapGamePress(button: button)
        case .results: break
        }
    }

    private func handleSideSelectionPress(button: CheerMeterWidgetViewButtons) {
        switch button {
        case .leftChoice:
            mySide = .left
            cheerMeter.animateLeftSelectionCenter {
                self.state = .tutorial
            }
        case .rightChoice:
            mySide = .right
            cheerMeter.animateRightSelectionCenter {
                self.state = .tutorial
            }
        }
    }

    private func handleTapGamePress(button: CheerMeterWidgetViewButtons) {
        myScore += 1
        cheerMeter.score = myScore.description

        switch button {
        case .leftChoice:
            cheerMeter.flashLeftPowerBar()
            voteClient.sendVote(voteURL: leftCheerOption.voteUrl)
        case .rightChoice:
            cheerMeter.flashRightPowerBar()
            voteClient.sendVote(voteURL: rightCheerOption.voteUrl)
        }

        cheerMeter.playScoreAnimation()

        let now = Date()
        if firstTapTime == nil {
            firstTapTime = now
        }
        lastTapTime = now
    }
}

// MARK: - CheerMeterVoteClientDelegate

extension CheerMeterWidgetViewController: CheerMeterVoteClientDelegate {
    func didReceiveResults(_ results: CheerMeterResults) {
        guard state != .results else {
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
    var coreWidgetView: CoreWidgetView {
        return cheerMeter.coreWidgetView
    }

    func start() {
        state = .sideSelection
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
    class ResultsView: UIView {

        private let theme: Theme

        init(theme: Theme){
            self.theme = theme
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func playLose(completion: @escaping () -> Void) {
            let lottie = LOTAnimationView(filePath: theme.randomIncorrectAnimationAsset())
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
            let winLottie = LOTAnimationView(filePath: theme.randomCorrectAnimationAsset())
            winLottie.contentMode = .scaleAspectFit

            addSubview(winLottie)
            winLottie.constraintsFill(to: self)
            
            winLottie.play { complete in
                if complete {
                    UIView.animate(withDuration: 0.2, animations: {
                        winLottie.alpha = 0
                    }, completion: { _ in
                        completion()
                    })
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
        cache: Cache,
        theme: Theme
    ) {
        titleText = question
        leftChoiceText = leftChoice.description
        rightChoiceText = rightChoice.description
        timerDuration = CGFloat(duration)
        scoreTitle = "EngagementSDK.widget.CheerMeter.scoreTitle".localized(withComment: "Text to indicate your score.")
        instructionText = "EngagementSDK.widget.CheerMeter.instruction".localized(withComment: "Text to teach user how to play the game by tapping.")

        cache.get(key: leftChoice.imageUrl.absoluteString) { [weak self] (data: Data?) in
            guard
                let self = self,
                let image = data.flatMap(UIImage.init(data:))
            else {
                return
            }

            self.leftChoiceImage = image
        }
        cache.get(key: rightChoice.imageUrl.absoluteString) { [weak self] (data: Data?) in
            guard
                let self = self,
                let image = data.flatMap(UIImage.init(data:))
            else {
                return
            }

            self.rightChoiceImage = image
        }

        applyTheme(theme)
    }
}
