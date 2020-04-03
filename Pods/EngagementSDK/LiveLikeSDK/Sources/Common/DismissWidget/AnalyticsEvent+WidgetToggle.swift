//
//  AnalyticsEvent+WidgetToggle.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/17/19.
//

import Foundation

extension AnalyticsEvent {
    static func widgetToggleButtonPressed(pauseStatusWhenPressed: PauseStatus) -> AnalyticsEvent {
        let currentToggleStatus: CurrentToggleStatus
        switch pauseStatusWhenPressed {
        case .paused: currentToggleStatus = .off
        case .unpaused: currentToggleStatus = .on
        }

        return AnalyticsEvent(name: .widgetToggleButtonPressed, data: [
            .currentToggleStatus: currentToggleStatus.rawValue
        ])
    }

    static func widgetToggleActionSelected(selectedAction: SelectedAction, trigger: WidgetPauseDialogViewController.Trigger) -> AnalyticsEvent {
        let popupTrigger: PopupTrigger
        let triggerThreshold: Int
        switch trigger {
        case .togglePressed:
            popupTrigger = .triggeredByUser
            triggerThreshold = 0
        case let .passThreshold(threshold):
            popupTrigger = .automated
            triggerThreshold = threshold
        }

        return AnalyticsEvent(name: .widgetToggleActionSelected, data: [
            .selectedAction: selectedAction.rawValue,
            .popupTrigger: popupTrigger.rawValue,
            .automatedPopupTriggerThreshold: triggerThreshold
        ])
    }

    private enum CurrentToggleStatus: String {
        case on = "On"
        case off = "Off"
    }

    enum SelectedAction: String {
        case no = "No"
        case forNow = "For Now"
        case forever = "Forever"
    }

    private enum PopupTrigger: String {
        case triggeredByUser = "Triggered By User"
        case automated = "Automated"
    }
}

private extension AnalyticsEvent.Attribute {
    static let currentToggleStatus: Attribute = "Current Toggle Status"
    static let selectedAction: Attribute = "Selected Action"
    static let popupTrigger: Attribute = "Popup Trigger"
    static let automatedPopupTriggerThreshold: Attribute = "Automated Popup Trigger Threshold"
}

private extension AnalyticsEvent.Name {
    static let widgetToggleButtonPressed: Name = "Widget Toggle Button Pressed"
    static let widgetToggleActionSelected: Name = "Widget Toggle Action Selected"
}
