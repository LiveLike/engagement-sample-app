//
//  TimelineWidgetViewDelegate.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 2/24/21.
//

import Foundation

/// A Widget state controller based on a common timeline use-case
final public class TimelineWidgetViewDelegate: WidgetViewDelegate {
    public init() {}

    public func widgetDidEnterState(widget: WidgetViewModel, state: WidgetState) {
        switch state {
        case .ready:
            break
        case .interacting:
            widget.addTimer(seconds: widget.interactionTimeInterval ?? 5) { _ in
                widget.moveToNextState()
            }
        case .results:
            break
        case .finished:
            break
        }
    }

    public func widgetStateCanComplete(widget: WidgetViewModel, state: WidgetState) {
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

    public func userDidInteract(_ widget: WidgetViewModel) { }
}
