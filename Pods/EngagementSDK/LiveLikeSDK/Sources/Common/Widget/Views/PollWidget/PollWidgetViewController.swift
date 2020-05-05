//
//  File.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/14/19.
//

import UIKit

class PollWidgetViewController: WidgetController {

    // MARK: Internal Properties

    let id: String
    let kind: WidgetKind
    var interactionTimeInterval: TimeInterval?
    
    weak var delegate: WidgetEvents?
    var coreWidgetView: CoreWidgetView {
        return widgetView.coreWidgetView
    }
    
    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }

    var dismissSwipeableView: UIView {
        return self.view
    }

    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var customData: String?

    // MARK: Private Properties

    private(set) var widgetView: PollWidgetView
    private let pollVoteClient: PollWidgetVoteClient
    private var pollResultsClient: PollWidgetResultsClient
    private var updateChannel: String
    private var widgetVotePromise: Promise<WidgetVote>?
    private let debouncer = Debouncer<PollSelection>(delay: 0.5)

    // MARK: Analytics

    private let eventRecorder: EventRecorder
    private var timeDisplayed: Date = Date()
    private var firstTapTime: Date?
    private var lastTapTime: Date?
    private var tapCount = 0
    private var interactableState: InteractableState = .openToInteraction

    // MARK: Consts

    private let additionalTimeToViewResults: Double = 6.0

    // MARK: State Properties

    private var widgetVote: WidgetVote?
    
    convenience init(payload: ImagePollCreated,
                     pollWidgetView: PollWidgetView,
                     pollVoteClient: PollWidgetVoteClient,
                     pollResultsClient: PollWidgetResultsClient,
                     eventRecorder: EventRecorder,
                     options: Set<WidgetOption> = Set())
    {
        self.init(id: payload.id,
                  kind: payload.kind,
                  pollWidgetView: pollWidgetView,
                  pollVoteClient: pollVoteClient,
                  pollResultsClient: pollResultsClient,
                  updateChannel: payload.subscribeChannel,
                  eventRecorder: eventRecorder,
                  interactionTimeInterval: payload.timeout.timeInterval,
                  title: payload.question,
                  options: Set(payload.options.map({ WidgetOption(id: $0.id, text: $0.description, image: nil)})),
                  metadata: payload.customData)
        
    }
    
    convenience init(payload: TextPollCreated,
                     pollWidgetView: PollWidgetView,
                     pollVoteClient: PollWidgetVoteClient,
                     pollResultsClient: PollWidgetResultsClient,
                     eventRecorder: EventRecorder,
                     options: Set<WidgetOption> = Set())
    {
        self.init(id: payload.id,
                  kind: payload.kind,
                  pollWidgetView: pollWidgetView,
                  pollVoteClient: pollVoteClient,
                  pollResultsClient: pollResultsClient,
                  updateChannel: payload.subscribeChannel,
                  eventRecorder: eventRecorder,
                  interactionTimeInterval: payload.timeout.timeInterval,
                  title: payload.question,
                  options: Set(payload.options.map({ WidgetOption(id: $0.id, text: $0.description, image: nil)})),
                  metadata: payload.customData)
        
    }

    private init(id: String,
                 kind: WidgetKind,
                 pollWidgetView: PollWidgetView,
                 pollVoteClient: PollWidgetVoteClient,
                 pollResultsClient: PollWidgetResultsClient,
                 updateChannel: String,
                 eventRecorder: EventRecorder,
                 interactionTimeInterval: TimeInterval,
                 title: String = "",
                 options: Set<WidgetOption> = Set(),
                 metadata: String?)
    {
        widgetView = pollWidgetView
        self.id = id
        self.pollResultsClient = pollResultsClient
        self.pollVoteClient = pollVoteClient
        self.updateChannel = updateChannel
        self.kind = kind
        self.eventRecorder = eventRecorder
        self.widgetTitle = title
        self.options = options
        self.interactionTimeInterval = interactionTimeInterval
        self.customData = metadata
        super.init(nibName: nil, bundle: nil)

        configureVoteDebouncer()

        widgetView.onSelectionAction = { [weak self] selection in
            guard let self = self else { return }
            self.debouncer.call(value: selection)
            self.pollResultsClient.subscribeToUpdateChannel(self.updateChannel)
            let now = Date()
            if self.firstTapTime == nil {
                self.firstTapTime = now
            }
            self.lastTapTime = now
            self.tapCount += 1
        }

        self.pollResultsClient.didReceivePollResults = { [weak self] in
            self?.widgetView.updateResults(results: $0)
        }

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    private func configure() {
        view.addSubview(widgetView)
        widgetView.constraintsFill(to: view)
    }

    // MARK: Lifecycle Overrides

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollResultsClient.unsubscribeFromUpdateChannel(updateChannel)
    }

    func start() {
        widgetView.beginTimer { [weak self] in
            guard let self = self else { return }
            self.widgetView.lockSelections()
            self.interactableState = .closedToInteraction
            if let firstTapTime = self.firstTapTime, let lastTapTime = self.lastTapTime {
                // Analytics
                let properties = WidgetInteractedProperties(
                    widgetId: self.id,
                    widgetKind: self.kind.analyticsName,
                    firstTapTime: firstTapTime,
                    lastTapTime: lastTapTime,
                    numberOfTaps: self.tapCount,
                    interactionTimeInterval: self.interactionTimeInterval,
                    widgetViewModel: self
                )
                self.delegate?.widgetInteractionDidComplete(properties: properties)
            }
            self.widgetView.revealResults()
            self.pollResultsClient.subscribeToUpdateChannel(self.updateChannel)
            self.widgetView.beginCloseTimer(duration: self.additionalTimeToViewResults) { [weak self] dismissAction in
                guard let self = self else { return }
                self.delegate?.actionHandler(event: .dismiss(action: dismissAction))
            }
        }
        delegate?.widgetInteractionDidBegin(widget: self)

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

    // MARK: - Vote

    private func configureVoteDebouncer() {
        debouncer.callback = { [weak self] selection in
            guard let self = self else { return }
            if let votePromise = self.widgetVotePromise {
                // If request is pending recursively call debouncer until first vote is fulfilled or rejected.
                if votePromise.isPending {
                    self.debouncer.call(value: selection)
                    return
                }

                // If request is fullfilled, update vote.
                if votePromise.isFulfilled, let widgetVote = self.widgetVote {
                    self.updateVote(vote: widgetVote, optionId: selection.id)
                    return
                }
                // If request is rejected or widgetvote is nil, retry.
                self.setVote(selection: selection)
            } else {
                self.setVote(selection: selection)
            }
        }
    }

    private func setVote(selection: PollSelection) {
        widgetVotePromise = pollVoteClient.setVote(url: selection.url)

        widgetVotePromise?.then { vote in
            self.widgetVote = vote
            log.debug("Successfully submitted vote for option: \(vote.optionId)")
        }.catch { error in
            log.error("Failed to submit vote because: \(error.localizedDescription)")
        }
    }

    private func updateVote(vote: WidgetVote, optionId: String) {
        print("The request option is \(optionId)")
        pollVoteClient.updateVote(url: vote.url, optionId: optionId).then { updatedVote in
            self.widgetVote = updatedVote
            log.debug("Successfully updated vote to option: \(updatedVote.optionId)")
        }.catch { error in
            log.error("Failed to update vote because: \(error.localizedDescription)")
        }
    }
}
