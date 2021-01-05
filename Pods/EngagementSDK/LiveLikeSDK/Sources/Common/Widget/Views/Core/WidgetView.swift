//
//  WidgetView.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-31.
//

import UIKit

open class Widget: UIViewController, WidgetViewModel {

    // MARK: Public Properties

    public let id: String
    public let kind: WidgetKind
    public let widgetTitle: String?
    public let createdAt: Date
    public let publishedAt: Date?
    public let interactionTimeInterval: TimeInterval?
    public let options: Set<WidgetOption>?
    public let customData: String?

    public var previousState: WidgetState?
    public var currentState: WidgetState
    public weak var delegate: WidgetViewDelegate?
    public var userDidInteract: Bool
    public var theme: Theme
    public var dismissSwipeableView: UIView {
        return view
    }

    // MARK: Internal Properties

    let widgetLink: URL?
    let optionsArray: [WidgetOption]?
    var interactionCount: Int = 0
    var timeOfLastInteraction: Date?
    var interactableState: InteractableState = .closedToInteraction

    public init() {
        self.id = ""
        self.kind = .alert
        self.widgetTitle = nil
        self.createdAt = Date()
        self.publishedAt = nil
        self.interactionTimeInterval = nil
        self.optionsArray = []
        self.options = Set()
        self.customData = nil
        self.previousState = nil
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(
        id: String,
        kind: WidgetKind,
        widgetTitle: String?,
        createdAt: Date,
        publishedAt: Date?,
        interactionTimeInterval: TimeInterval?,
        options: [WidgetOption]
    ) {
        self.id = id
        self.kind = kind
        self.widgetTitle = widgetTitle
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.interactionTimeInterval = interactionTimeInterval
        self.optionsArray = options
        self.options = Set(options)
        self.customData = nil
        self.previousState = nil
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: CheerMeterWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.title
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.options.map {
            WidgetOption(
                id: $0.id,
                voteURL: $0.voteURL,
                text: $0.text,
                image: nil,
                voteCount: $0.voteCount
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = nil
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: AlertWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.title
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        self.optionsArray = nil
        self.options = nil
        self.customData = model.customData
        self.widgetLink = model.linkURL
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: QuizWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.question
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.choices.map {
            return WidgetOption(
                id: $0.id,
                voteURL: $0.answerURL,
                text: $0.text,
                image: nil,
                imageURL: $0.imageURL,
                isCorrect: $0.isCorrect,
                voteCount: $0.answerCount
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = model.customData
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: PredictionWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.question
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.options.map {
            return WidgetOption(
                id: $0.id,
                voteURL: $0.voteURL,
                text: $0.text,
                image: nil,
                imageURL: $0.imageURL,
                isCorrect: nil,
                voteCount: $0.voteCount
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = model.customData
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: PredictionFollowUpWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.question
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.options.map {
            return WidgetOption(
                id: $0.id,
                voteURL: nil,
                text: $0.text,
                image: nil,
                imageURL: $0.imageURL,
                isCorrect: nil,
                voteCount: $0.voteCount
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = model.customData
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: PollWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.question
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.options.map {
            return WidgetOption(
                id: $0.id,
                voteURL: $0.voteURL,
                text: $0.text,
                image: nil,
                imageURL: $0.imageURL,
                voteCount: $0.voteCount
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = model.customData
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    public init(model: ImageSliderWidgetModel) {
        self.id = model.id
        self.kind = model.kind
        self.widgetTitle = model.question
        self.createdAt = model.createdAt
        self.publishedAt = model.publishedAt
        self.interactionTimeInterval = model.interactionTimeInterval
        self.currentState = .ready
        self.userDidInteract = false
        self.theme = Theme()
        let opts = model.options.map {
            return WidgetOption(
                id: $0.id,
                voteURL: nil,
                text: nil,
                image: nil,
                imageURL: $0.imageURL,
                voteCount: nil
            )
        }
        self.optionsArray = opts
        self.options = Set(opts)
        self.customData = model.customData
        self.widgetLink = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func moveToNextState() { }
    public func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) { }
    public func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) { }
}
