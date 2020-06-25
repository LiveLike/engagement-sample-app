//
//  QuizWidgetViewController.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import UIKit

typealias QuizSelection = (optionId: String, answerUrl: URL)

class QuizWidgetViewController: WidgetController {

    // MARK: - Internal Properties

    let id: String
    let kind: WidgetKind
    let interactionTimeInterval: TimeInterval?
    weak var delegate: WidgetEvents?
    var dismissSwipeableView: UIView {
        return self.view
    }
    var widgetTitle: String?
    var options: Set<WidgetOption>?
    var customData: String?
    var userDidInteract: Bool = false
    var previousState: WidgetState?
    var currentState: WidgetState = .ready {
        willSet {
            previousState = self.currentState
        }
        didSet {
            delegate?.widgetDidEnterState(widget: self, state: currentState)
            switch currentState {
            case .ready:
                break
            case .interacting:
                enterInteractingState()
            case .results:
                enterResultsState()
            case .finished:
                enterFinishedState()
            }
        }
    }

    // MARK: - Private Stored Properties

    private(set) var quizWidget: QuizWidgetView
    private let quizVoteClient: QuizWidgetVoteClient
    private var quizResultsClient: QuizWidgetResultsClient

    private var myQuizSelection: QuizSelection?

    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var timeDisplayed = Date()
    private var interactableState: InteractableState = .openToInteraction
    private var firstTapTime: Date?
    private var lastTapTime: Date?
    private var tapCount = 0

    private let additionalTimeAfterAnswerReveal: TimeInterval = 6

    // MARK: - Initializers
    
    convenience init(payload: TextQuizCreated,
                     quizWidget: QuizWidgetView,
                     quizVoteClient: QuizWidgetVoteClient,
                     quizResultsClient: QuizWidgetResultsClient,
                     eventRecorder: EventRecorder)
    {
        let options = Set(payload.choices.map({
            WidgetOption(id: $0.id,
                         text: $0.description,
                         image: nil,
                         isCorrect: $0.isCorrect)
        }))
        
        self.init(id: payload.id,
                  kind: payload.kind,
                  widgetView: quizWidget,
                  voteClient: quizVoteClient,
                  resultsClient: quizResultsClient,
                  eventRecorder: eventRecorder,
                  widgetTitle: payload.question,
                  options: options,
                  interactionTimeInterval: payload.timeout.timeInterval,
                  metadata: payload.customData)
    }
    
    convenience init(payload: ImageQuizCreated,
                     quizWidget: QuizWidgetView,
                     quizVoteClient: QuizWidgetVoteClient,
                     quizResultsClient: QuizWidgetResultsClient,
                     eventRecorder: EventRecorder)
    {
        let options = Set(payload.choices.map({
            WidgetOption(id: $0.id,
                         text: $0.description,
                         image: nil,
                         isCorrect: $0.isCorrect)
        }))
        
        self.init(id: payload.id,
                  kind: payload.kind,
                  widgetView: quizWidget,
                  voteClient: quizVoteClient,
                  resultsClient: quizResultsClient,
                  eventRecorder: eventRecorder,
                  widgetTitle: payload.question,
                  options: options,
                  interactionTimeInterval: payload.timeout.timeInterval,
                  metadata: payload.customData)
    }
    
    private init(id: String,
                 kind: WidgetKind,
                 widgetView: QuizWidgetView,
                 voteClient: QuizWidgetVoteClient,
                 resultsClient: QuizWidgetResultsClient,
                 eventRecorder: EventRecorder,
                 widgetTitle: String,
                 options: Set<WidgetOption>?,
                 interactionTimeInterval: TimeInterval?,
                 metadata: String?)
    {
        self.id = id
        self.kind = kind
        self.quizWidget = widgetView
        self.quizVoteClient = voteClient
        self.quizResultsClient = resultsClient
        self.eventRecorder = eventRecorder
        self.widgetTitle = widgetTitle
        self.options = options
        self.interactionTimeInterval = interactionTimeInterval
        self.customData = metadata
        
        super.init(nibName: nil, bundle: nil)
        
        self.quizWidget.didSelectChoice = { [weak self] in
            guard let self = self else { return }
            self.userDidInteract = true
            self.myQuizSelection = $0
            let now = Date()
            if self.firstTapTime == nil {
                self.firstTapTime = now
            }
            self.lastTapTime = now
            self.tapCount += 1
        }

        self.quizResultsClient.didReceiveResults = { [weak self] results in
            self?.quizWidget.updateResults(results)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
}

// MARK: - View Lifecycle

extension QuizWidgetViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(quizWidget)
        quizWidget.constraintsFill(to: view)
        quizWidget.isUserInteractionEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        quizResultsClient.unsubscribe()
    }
}

// MARK: - WidgetViewModel

extension QuizWidgetViewController {
    
    func moveToNextState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
    }
    
    func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        quizWidget.showCloseButton {
            completion(self)
        }
    }
    
    func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        quizWidget.beginTimer(seconds: seconds) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }

    func willDismiss(dismissAction: DismissAction) {
        if dismissAction.userDismissed {
            var properties = WidgetDismissedProperties(
                widgetId: id,
                widgetKind: kind.analyticsName,
                dismissAction: dismissAction,
                numberOfTaps: tapCount,
                dismissSecondsSinceStart: Date().timeIntervalSince(timeDisplayed)
            )
            if let lastTapTime = self.lastTapTime {
                properties.dismissSecondsSinceLastTap = Date().timeIntervalSince(lastTapTime)
            }
            properties.interactableState = interactableState
            eventRecorder.record(.widgetUserDismissed(properties: properties))
            currentState = .finished
        }
    }
}

// MARK: - Private APIs

private extension QuizWidgetViewController {
    
    // MARK: Handle States
    
    func enterInteractingState() {
        quizWidget.isUserInteractionEnabled = true
        timeDisplayed = Date()
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: id))
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    func enterResultsState() {
        quizResultsClient.subscribe()
        quizWidget.lockSelection()
        interactableState = .closedToInteraction
        
        guard let myQuizSelection = self.myQuizSelection else {
            self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            return
        }
        
        self.quizVoteClient.vote(url: myQuizSelection.answerUrl) { [weak self] result in
            guard let self = self else { return }
            self.quizWidget.revealAnswer(myOptionId: myQuizSelection.optionId) {
                switch result {
                case .success:
                    log.debug("Successfully submitted answer.")
                case .failure(let error):
                    log.error("Failed to submit answer: \(error.localizedDescription)")
                }
                self.delegate?.widgetStateCanComplete(widget: self, state: .results)
            }
        }
    }
    
    func enterFinishedState() {
        quizWidget.stopAnswerRevealAnimation()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
    
    func createWidgetInteractedProperties() -> WidgetInteractedProperties {
        return WidgetInteractedProperties(
            widgetId: self.id,
            widgetKind: self.kind.analyticsName,
            firstTapTime: self.firstTapTime,
            lastTapTime: self.lastTapTime,
            numberOfTaps: self.tapCount,
            interactionTimeInterval: self.interactionTimeInterval,
            widgetViewModel: self,
            previousState: previousState ?? .interacting,
            currentState: currentState
        )
    }
}
