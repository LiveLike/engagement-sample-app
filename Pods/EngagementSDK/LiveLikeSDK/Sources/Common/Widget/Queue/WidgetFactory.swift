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
            // MARK: Text Predictions
        case let .textPredictionCreated(payload):
            let predictionClient = PredictionClient(
                accessToken: accessToken,
                widgetClient: widgetMessagingOutput,
                resultsChannel: payload.subscribeChannel
            )
            let viewmodel = ChoiceWidgetViewModel.make(from: payload)
            let widget = PredictionWidgetViewController(style: .text,
                                                        kind: payload.kind,
                                                        widgetData: viewmodel,
                                                        voteRepo: voteRepo,
                                                        theme: theme,
                                                        predictionWidgetClient: predictionClient,
                                                        eventRecorder: eventRecorder,
                                                        title: payload.question,
                                                        options: Set(payload.options.map({ WidgetOption(id: $0.id,
                                                                                                        text: $0.description,
                                                                                                        image: nil) })))
            return widget
            // MARK: Text Predictions Follow Up
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
                                                          widgetConfig: widgetConfig,
                                                          title: payload.question,
                                                          options: Set(payload.options.map({ WidgetOption(id: $0.id,
                                                                                                          text: $0.description,
                                                                                                          image: nil) })))
            return widget
            // MARK: Image Predictions
        case let .imagePredictionCreated(payload):
            let predictionClient = PredictionClient(
                accessToken: accessToken,
                widgetClient: widgetMessagingOutput,
                resultsChannel: payload.subscribeChannel
            )
            let viewmodel = ChoiceWidgetViewModel.make(from: payload)
            let widget = PredictionWidgetViewController(style: .image,
                                                        kind: payload.kind,
                                                        widgetData: viewmodel,
                                                        voteRepo: voteRepo,
                                                        theme: theme,
                                                        predictionWidgetClient: predictionClient,
                                                        eventRecorder: eventRecorder,
                                                        title: payload.question,
                                                        options: Set(payload.options.map({ WidgetOption(id: $0.id,
                                                                                                        text: $0.description,
                                                                                                        image: nil) })))
            return widget
            // MARK: Image Prediction Follow Up
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
                                                          widgetConfig: widgetConfig,
                                                          title: payload.question,
                                                          options: Set(payload.options.map({ WidgetOption(id: $0.id,
                                                                                                          text: $0.description,
                                                                                                          image: nil) })))
            return widget
            // MARK: Image Poll
        case let .imagePollCreated(payload):
            let pollWidgetClient = PollClient(widgetMessagingClient: widgetMessagingOutput, accessToken: accessToken)
            let choiceFactory = ChoiceWidgetOptionFactory()
            let imagePollWidget = TextPollWidgetView(data: payload,
                                                     theme: theme,
                                                     choiceOptionFactory: choiceFactory,
                                                     widgetConfig: widgetConfig)
            let widget = PollWidgetViewController(payload: payload,
                                                  pollWidgetView: imagePollWidget,
                                                  pollVoteClient: pollWidgetClient,
                                                  pollResultsClient: pollWidgetClient,
                                                  eventRecorder: eventRecorder)
            return widget
            // MARK: Text Poll
        case let .textPollCreated(payload):
            let pollWidgetClient = PollClient(widgetMessagingClient: widgetMessagingOutput, accessToken: accessToken)
            let choiceFactory = ChoiceWidgetOptionFactory()
            let textPollWidget = TextPollWidgetView(data: payload,
                                                    theme: theme,
                                                    choiceOptionFactory: choiceFactory,
                                                    widgetConfig: widgetConfig)
            let widget = PollWidgetViewController(payload: payload,
                                                  pollWidgetView: textPollWidget,
                                                  pollVoteClient: pollWidgetClient,
                                                  pollResultsClient: pollWidgetClient,
                                                  eventRecorder: eventRecorder)
            return widget
            // MARK: Alert
        case let .alertCreated(payload):
            let widget = AlertWidgetViewController(widgetData: payload,
                                                   theme: theme,
                                                   kind: payload.kind,
                                                   eventRecorder: eventRecorder)
            return widget
            // MARK: Text Quiz
        case let .textQuizCreated(payload):
            let resultsClient = QuizClient(widgetMessagingClient: widgetMessagingOutput,
                                           updateChannel: payload.subscribeChannel,
                                           accessToken: accessToken)
            let textQuizWidget = TextQuizWidgetView(data: payload,
                                                    theme: theme,
                                                    widgetConfig: widgetConfig)
            let widget = QuizWidgetViewController(payload: payload,
                                                  quizWidget: textQuizWidget,
                                                  quizVoteClient: resultsClient,
                                                  quizResultsClient: resultsClient,
                                                  eventRecorder: eventRecorder)
            return widget
            // MARK: Image Quiz
        case let .imageQuizCreated(payload):
            let resultsClient = QuizClient(widgetMessagingClient: widgetMessagingOutput,
                                           updateChannel: payload.subscribeChannel,
                                           accessToken: accessToken)
            let imageQuizWidget = ImageQuizWidgetView(data: payload,
                                                      cache: Cache.shared,
                                                      theme: theme,
                                                      widgetConfig: widgetConfig)
            let widget = QuizWidgetViewController(payload: payload,
                                                  quizWidget: imageQuizWidget,
                                                  quizVoteClient: resultsClient,
                                                  quizResultsClient: resultsClient,
                                                  eventRecorder: eventRecorder)
            return widget
            // MARK: Image Slider
        case let .imageSliderCreated(payload):
            let imageSliderClient = ImageSliderClient(widgetMessagingClient: widgetMessagingOutput,
                                                      updateChannel: payload.subscribeChannel,
                                                      accessToken: accessToken)
            let imageSliderWidget = ImageSliderViewController(imageSliderCreated: payload,
                                                              resultsClient: imageSliderClient,
                                                              imageSliderVoteClient: imageSliderClient,
                                                              theme: theme,
                                                              eventRecorder: eventRecorder,
                                                              widgetConfig: widgetConfig,
                                                              title: payload.question,
                                                              options: Set(payload.options.map({ WidgetOption(id: $0.id,
                                                                                                              text: nil,
                                                                                                              image: nil) })))
            return imageSliderWidget
            // MARK: Cheer Meter
        case let .cheerMeterCreated(payload):
            do {
                let voteClient = LiveCheerMeterVoteClient(widgetMessagingClient: widgetMessagingOutput,
                                                          subscribeChannel: payload.subscribeChannel,
                                                          accessToken: accessToken)
                return try CheerMeterWidgetViewController(cheerMeterData: payload,
                                                          voteClient: voteClient,
                                                          theme: theme,
                                                          eventRecorder: eventRecorder)
            } catch {
                log.error(error.localizedDescription)
                return nil
            }
            // MARK: Points Tutorial
        case let .pointsTutorial(awardsViewModel):
            return GamificationTutorialWidget(theme: theme,
                                              awards: awardsViewModel,
                                              eventRecorder: self.eventRecorder)
            // MARK: Bagde Collection
        case let .badgeCollect(awardsViewModel):
            guard let badgeToCollect = awardsViewModel.newBadgeEarned else { return nil }
            return BadgeCollectWidget(theme: theme,
                                      badgeToCollect: badgeToCollect,
                                      eventRecorder: self.eventRecorder)
            // MARK: Text Quiz Results
        case .textQuizResults,
             .imagePollResults,
             .imageQuizResults,
             .imageSliderResults,
             .cheerMeterResults,
             .textPredictionResults,
             .imagePredictionResults:
            return nil
        }
    }
}
