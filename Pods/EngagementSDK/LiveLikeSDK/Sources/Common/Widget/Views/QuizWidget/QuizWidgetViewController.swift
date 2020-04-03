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
    weak var delegate: WidgetEvents?
    var dismissSwipeableView: UIView {
        return self.view
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

    init(id: String, kind: WidgetKind, quizWidget: QuizWidgetView, quizVoteClient: QuizWidgetVoteClient, quizResultsClient: QuizWidgetResultsClient, eventRecorder: EventRecorder) {
        self.id = id
        self.kind = kind
        self.quizWidget = quizWidget
        self.quizVoteClient = quizVoteClient
        self.quizResultsClient = quizResultsClient
        self.eventRecorder = eventRecorder
        super.init(nibName: nil, bundle: nil)

        self.quizWidget.didSelectChoice = { [weak self] in
            guard let self = self else { return }
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        quizResultsClient.unsubscribe()
    }
}

// MARK: - WidgetViewModel

extension QuizWidgetViewController {
    var coreWidgetView: CoreWidgetView {
        return quizWidget.coreWidgetView
    }

    func start() {
        // begin timer
        quizWidget.beginTimer { [weak self] in
            guard let self = self else { return }
            self.timerCompleted()
        }
        timeDisplayed = Date()
        eventRecorder.record(.widgetDisplayed(kind: kind.analyticsName,
                                              widgetId: id))
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
        }
    }
}

// MARK: - Private APIs

private extension QuizWidgetViewController {
    func timerCompleted() {
        quizResultsClient.subscribe()
        quizWidget.lockSelection()
        interactableState = .closedToInteraction

        if let myQuizSelection = self.myQuizSelection {
            firstly {
                self.quizVoteClient.vote(url: myQuizSelection.answerUrl)
            }.then { _ in
                self.quizWidget.revealAnswer(myOptionId: myQuizSelection.optionId)
                if let firstTapTime = self.firstTapTime, let lastTapTime = self.lastTapTime {
                    let properties = WidgetInteractedProperties(
                        widgetId: self.id,
                        widgetKind: self.kind.analyticsName,
                        firstTapTime: firstTapTime,
                        lastTapTime: lastTapTime,
                        numberOfTaps: self.tapCount
                    )
                    self.delegate?.widgetInteractionDidComplete(properties: properties)
                }
                log.debug("Successfully submitted answer.")
            }.catch { error in
                log.error("Failed to submit answer: \(error.localizedDescription)")
            }
        }

        startDismissTimer()
    }

    func startDismissTimer() {
        quizWidget.beginCloseTimer(duration: additionalTimeAfterAnswerReveal) { [weak self] dismissAction in
            guard let self = self else { return }
            self.delegate?.actionHandler(event: .dismiss(action: dismissAction))
        }
    }
}
