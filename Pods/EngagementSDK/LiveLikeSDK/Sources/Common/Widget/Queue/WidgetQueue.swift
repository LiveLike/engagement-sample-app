//
//  WidgetQueue.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-22.
//

import UIKit

/// Transforms ClientEvent into WidgetViews and sends to WidgetRenderer
class WidgetQueue: WidgetProxyInput {
    /// Internal
    weak var renderer: WidgetRenderer? {
        didSet {
            self.renderer?.subscribe(widgetEventsDelegate: self)
            self.renderer?.subscribe(widgetRendererDelegate: self)
        }
    }

    weak var widgetProcessor: WidgetProcessor?

    var isRendering: Bool = false {
        didSet {
            widgetProcessor?.isProcessing = isRendering
        }
    }

    var widgetRendererListeners = Listener<WidgetRendererDelegate>()
    var widgetEventListeners = Listener<WidgetEvents>()

    private let voteRepo: WidgetVotes
    private let widgetMessagingOutput: WidgetClient
    private let accessToken: AccessToken
    let eventRecorder: EventRecorder

    init(widgetProcessor: WidgetProcessor, voteRepo: WidgetVotes, widgetMessagingOutput: WidgetClient, accessToken: AccessToken, eventRecorder: EventRecorder) {
        self.widgetProcessor = widgetProcessor
        self.voteRepo = voteRepo
        self.widgetMessagingOutput = widgetMessagingOutput
        self.accessToken = accessToken
        self.eventRecorder = eventRecorder
    }

    deinit {
        widgetRendererListeners.removeAll()
    }

    func publish(event: ClientEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.renderer?.displayWidget(from: ClientEventWidgetFactory(event: event, voteRepo: self.voteRepo, widgetMessagingOutput: self.widgetMessagingOutput, accessToken: self.accessToken, eventRecorder: self.eventRecorder))
        }
    }

    func discard(event: ClientEvent, reason: DiscardedReason) {
        log.info("Discarded widget \(event) -> \(reason)")
    }

    func connectionStatusDidChange(_ status: ConnectionStatus) {
        log.info("Widget connection status did change: \(status)")
    }

    func error(_ error: Error) {
        log.error("Widget Proxy Error: \(error)")
    }
}

// Internal facade for WidgetViewController:WidgetRenderer
extension WidgetQueue: WidgetRendererDelegate {
    func widgetWillStopRendering(widget: WidgetViewModel) {
        widgetRendererListeners.publish { $0.widgetWillStopRendering(widget: widget) }
    }
    
    func widgetDidStopRendering(widget: WidgetViewModel, dismissAction: DismissAction) {
        isRendering = false
        widgetRendererListeners.publish { $0.widgetDidStopRendering(widget: widget, dismissAction: dismissAction) }
    }

    func widgetDidStartRendering(widget: WidgetController) {
        isRendering = true
        widgetRendererListeners.publish { $0.widgetDidStartRendering(widget: widget) }
    }
}

extension WidgetQueue: PauseDelegate {
    func pauseStatusDidChange(status: PauseStatus) {
        if status == .paused {
            renderer?.dismissWidget(direction: .up)
        }
    }
}

extension WidgetQueue: WidgetRenderer {
    func subscribe(widgetEventsDelegate: WidgetEvents) {
        self.widgetEventListeners.addListener(widgetEventsDelegate)
    }
    
    func unsubscribe(widgetEventsDelegate: WidgetEvents) {
        self.widgetEventListeners.removeListener(widgetEventsDelegate)
    }
    
    func subscribe(widgetRendererDelegate: WidgetRendererDelegate) {
        self.widgetRendererListeners.addListener(widgetRendererDelegate)
    }
    
    func unsubscribe(widgetRendererDelegate: WidgetRendererDelegate) {
        self.widgetRendererListeners.removeListener(widgetRendererDelegate)
    }
    
    func displayWidget(handler: @escaping (Theme) -> WidgetController) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.renderer?.displayWidget(handler: handler)
        }
    }

    func displayWidget(from widgetFactory: WidgetFactory) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.renderer?.displayWidget(from: widgetFactory)
        }
    }

    func dismissWidget(direction: Direction) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.renderer?.dismissWidget(direction: direction)
        }
    }
}

/// Facade for widget events
extension WidgetQueue: WidgetEvents {
    func actionHandler(event: WidgetEvent) {
        widgetEventListeners.publish { $0.actionHandler(event: event) }
    }

    func widgetInteractionDidComplete(properties: WidgetInteractedProperties) {
        widgetEventListeners.publish { $0.widgetInteractionDidComplete(properties: properties) }
    }
}

protocol WidgetRenderer: WidgetRendererDelegator, WidgetEventsDelegator {
    var isRendering: Bool { get }
    func displayWidget(handler: @escaping (Theme) -> WidgetController)
    func displayWidget(from widgetFactory: WidgetFactory)
    func dismissWidget(direction: Direction)
}

protocol WidgetRendererDelegator: AnyObject {
    func subscribe(widgetRendererDelegate: WidgetRendererDelegate)
    func unsubscribe(widgetRendererDelegate: WidgetRendererDelegate)
}

protocol WidgetEventsDelegator: AnyObject {
    func subscribe(widgetEventsDelegate: WidgetEvents)
    func unsubscribe(widgetEventsDelegate: WidgetEvents)
}
