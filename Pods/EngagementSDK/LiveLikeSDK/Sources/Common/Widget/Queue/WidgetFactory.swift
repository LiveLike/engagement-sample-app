//
//  WidgetFactory.swift
//  EngagementSDK
//
//  Created by jelzon on 4/8/19.
//

import Foundation

protocol WidgetFactory {
    func create(theme: Theme, widgetConfig: WidgetConfig) -> WidgetController?
}

class DemoWidgetFactory: WidgetFactory {
    private let widget: WidgetController

    init(widget: WidgetController) {
        self.widget = widget
    }

    func create(theme: Theme, widgetConfig: WidgetConfig) -> WidgetController? {
        return widget
    }
}

// swiftlint:disable function_body_length
class ClientEventWidgetFactory: WidgetFactory {
    private let event: ClientEvent
    private let voteRepo: WidgetVotes
    private let widgetMessagingOutput: WidgetClient
    private let accessToken: AccessToken
    private let eventRecorder: EventRecorder

    init(event: ClientEvent, voteRepo: WidgetVotes, widgetMessagingOutput: WidgetClient, accessToken: AccessToken, eventRecorder: EventRecorder) {
        self.event = event
        self.voteRepo = voteRepo
        self.widgetMessagingOutput = widgetMessagingOutput
        self.accessToken = accessToken
        self.eventRecorder = eventRecorder
    }

    func create(theme: Theme = .dark, widgetConfig: WidgetConfig) -> WidgetController? {
        switch event {
        case let .textPredictionCreated(payload):
            let predictionClient = PredictionClient(accessToken: accessToken)
            let viewmodel = ChoiceWidgetViewModel.make(from: payload)
            let widget = PredictionWidgetViewController(style: .text, kind: payload.kind, widgetData: viewmodel, voteRepo: voteRepo, theme: theme, predictionWidgetClient: predictionClient, eventRecorder: eventRecorder)
            return widget
        case let .textPredictionFollowUp(payload, vote):
            guard let vote = vote else {
                log.error("There is not vote associated to this textPredictionFollowUp widget.")
                return nil
            }
            let viewmodel = ChoiceWidgetViewModel.make(from: payload, theme: theme)
            let widget = PredictionFollowUpViewController(type: .text,
                                                          widgetData: viewmodel,
                                                          voteID: vote.optionId,
                                                          theme: theme,
                                                          kind: payload.kind,
                                                          correctOptionIds: payload.correctOptionsIds,
                                                          eventRecorder: eventRecorder,
                                                          widgetConfig: widgetConfig)
            return widget
        case let .imagePredictionCreated(payload):
            let predictionClient = PredictionClient(accessToken: accessToken)
            let viewmodel = ChoiceWidgetViewModel.make(from: payload)
            let widget = PredictionWidgetViewController(style: .image,
                                                        kind: payload.kind,
                                                        widgetData: viewmodel,
                                                        voteRepo: voteRepo,
                                                        theme: theme,
                                                        predictionWidgetClient: predictionClient,
                                                        eventRecorder: eventRecorder)
            return widget
        case let .imagePredictionFollowUp(payload, vote):
            guard let vote = vote else {
                log.error("There is not vote associated to this imagePredictionFollowUp widget.")
                return nil
            }
            let viewmodel = ChoiceWidgetViewModel.make(from: payload, theme: theme)
            let widget = PredictionFollowUpViewController(type: .image,
                                                          widgetData: viewmodel,
                                                          voteID: vote.optionId,
                                                          theme: theme,
                                                          kind: payload.kind,
                                                          correctOptionIds: payload.correctOptionsIds,
                                                          eventRecorder: eventRecorder,
                                                          widgetConfig: widgetConfig)
            return widget
        case let .imagePollCreated(payload):
            let pollWidgetClient = PollClient(widgetMessagingClient: widgetMessagingOutput, accessToken: accessToken)
            let choiceFactory = ChoiceWidgetOptionFactory()
            let imagePollWidget = TextPollWidgetView(data: payload, theme: theme, choiceOptionFactory: choiceFactory, widgetConfig: widgetConfig)
            let widget = PollWidgetViewController(id: payload.id,
                                                  kind: payload.kind,
                                                  pollWidgetView: imagePollWidget,
                                                  pollVoteClient: pollWidgetClient,
                                                  pollResultsClient: pollWidgetClient,
                                                  updateChannel: payload.subscribeChannel,
                                                  eventRecorder: eventRecorder)
            return widget
        case let .textPollCreated(payload):
            let pollWidgetClient = PollClient(widgetMessagingClient: widgetMessagingOutput, accessToken: accessToken)
            let choiceFactory = ChoiceWidgetOptionFactory()
            let textPollWidget = TextPollWidgetView(data: payload, theme: theme, choiceOptionFactory: choiceFactory, widgetConfig: widgetConfig)
            let widget = PollWidgetViewController(id: payload.id,
                                                  kind: payload.kind,
                                                  pollWidgetView: textPollWidget,
                                                  pollVoteClient: pollWidgetClient,
                                                  pollResultsClient: pollWidgetClient,
                                                  updateChannel: payload.subscribeChannel,
                                                  eventRecorder: eventRecorder)
            return widget
        case let .alertCreated(payload):
            let widget = AlertWidgetViewController(widgetData: payload,
                                                   theme: theme,
                                                   kind: payload.kind,
                                                   eventRecorder: eventRecorder)
            return widget
        case let .textQuizCreated(payload):
            let resultsClient = QuizClient(widgetMessagingClient: widgetMessagingOutput, updateChannel: payload.subscribeChannel, accessToken: accessToken)
            let textQuizWidget = TextQuizWidgetView(data: payload,
                                                    theme: theme,
                                                    widgetConfig: widgetConfig)
            let widget = QuizWidgetViewController(id: payload.id,
                                                  kind: payload.kind,
                                                  quizWidget: textQuizWidget,
                                                  quizVoteClient: resultsClient,
                                                  quizResultsClient: resultsClient,
                                                  eventRecorder: eventRecorder)
            return widget
        case let .imageQuizCreated(payload):
            let resultsClient = QuizClient(widgetMessagingClient: widgetMessagingOutput, updateChannel: payload.subscribeChannel, accessToken: accessToken)
            let imageQuizWidget = ImageQuizWidgetView(data: payload,
                                                      cache: Cache.shared,
                                                      theme: theme,
                                                      widgetConfig: widgetConfig)
            let widget = QuizWidgetViewController(id: payload.id,
                                                  kind: payload.kind,
                                                  quizWidget: imageQuizWidget,
                                                  quizVoteClient: resultsClient,
                                                  quizResultsClient: resultsClient,
                                                  eventRecorder: eventRecorder)
            return widget
        case let .imageSliderCreated(payload):
            let imageSliderClient = ImageSliderClient(widgetMessagingClient: widgetMessagingOutput, updateChannel: payload.subscribeChannel, accessToken: accessToken)
            let imageSliderWidget = ImageSliderViewController(imageSliderCreated: payload,
                                                              resultsClient: imageSliderClient,
                                                              imageSliderVoteClient: imageSliderClient,
                                                              theme: theme,
                                                              eventRecorder: eventRecorder,
                                                              widgetConfig: widgetConfig)
            return imageSliderWidget
        case let .cheerMeterCreated(payload):
            do {
                let voteClient = LiveCheerMeterVoteClient(widgetMessagingClient: widgetMessagingOutput, subscribeChannel: payload.subscribeChannel, accessToken: accessToken)
                return try CheerMeterWidgetViewController(cheerMeterData: payload, voteClient: voteClient, theme: theme, eventRecorder: eventRecorder)
            } catch {
                log.error(error.localizedDescription)
                return nil
            }
        case let .pointsTutorial(awardsViewModel):
            return GamificationTutorialWidget(theme: theme, awards: awardsViewModel, eventRecorder: self.eventRecorder)
        case let .badgeCollect(awardsViewModel):
            guard let badgeToCollect = awardsViewModel.newBadgeEarned else { return nil }
            return BadgeCollectWidget(theme: theme, badgeToCollect: badgeToCollect, eventRecorder: self.eventRecorder)
        case .textQuizResults, .imagePollResults, .imageQuizResults, .imageSliderResults, .cheerMeterResults:
            return nil
        }
    }
}
