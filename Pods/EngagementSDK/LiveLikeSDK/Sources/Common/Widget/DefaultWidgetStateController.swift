//
//  DefaultWidgetStateController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/21/20.
//

import Foundation

public class DefaultWidgetStateController {
    
    private let closeButtonAction: () -> Void
    private let widgetFinishedCompletion: (WidgetViewModel) -> Void
    
    public init(
        closeButtonAction: @escaping () -> Void,
        widgetFinishedCompletion: @escaping (WidgetViewModel) -> Void
    ) {
        self.closeButtonAction = closeButtonAction
        self.widgetFinishedCompletion = widgetFinishedCompletion
    }
}

extension DefaultWidgetStateController: WidgetViewDelegate {
    public func widgetDidEnterState(widget: WidgetViewModel, state: WidgetState) {
        log.info("Widget Did Enter State: \(String(describing: state))")
        switch state {
        case .ready:
            break
        case .interacting:
            widget.addTimer(seconds: widget.interactionTimeInterval ?? 5) { _ in
                widget.moveToNextState()
            }
        case .results:
            widget.addCloseButton { [weak self] _ in
                self?.closeButtonAction()
            }
        case .finished:
            // If the user did not interact with the widget then dismiss immediately
            // Otherwise dismiss the widget after a few seconds
            if !widget.userDidInteract && widget.kind != .alert {
                self.widgetFinishedCompletion(widget)
            } else {
                delay(6) { [weak self] in
                    self?.widgetFinishedCompletion(widget)
                }
            }
        }
    }
    
    public func widgetStateCanComplete(widget: WidgetViewModel, state: WidgetState) {
        log.info("Widget State Can Complete: \(String(describing: state))")
        switch state {
        case .ready:
            break
        case .interacting:
            break
        case .results:
            if widget.kind == .imagePredictionFollowUp || widget.kind == .textPredictionFollowUp {
                widget.addTimer(seconds: widget.interactionTimeInterval ?? 5) { _ in
                    widget.moveToNextState()
                }
            } else {
                widget.moveToNextState()
            }
        case .finished:
            break
        }
    }
    
    public func userDidInteract(_ widget: WidgetViewModel) {
        log.info("\(widget.kind.displayName) Widget Did Recieve Interaction")
    }
}
