//
//  WidgetToggle.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/6/19.
//

import UIKit

/**
 A plugin for the EngagementSDK to empower your users to toggle widgets at will.
 */
@objc(LLWidgetToggle)
public class WidgetToggle: NSObject, Plugin, ResolveablePlugin {
    let triggerThreshold: Int
    let theme: Theme
    let toggleParentView: UIView

    /**
     Init using custom settings
     - Parameter triggerThreshold: The number of dismisses it takes to trigger the initial disable dialog
     - Parameter theme: The theme to apply to the disable/enable dialog
     - Parameter toggleParentView: The view that the toggle button will be added as a subview
     */
    @objc
    public required init(triggerThreshold: Int, theme: Theme, toggleParentView: UIView) {
        self.triggerThreshold = triggerThreshold
        self.theme = theme
        self.toggleParentView = toggleParentView
    }

    /**
     Init using default settings
     - Parameter toggleParentView: The view that the toggle button will be added as a subview
     */
    @objc
    public convenience init(toggleParentView: UIView) {
        self.init(triggerThreshold: 3, theme: .dark, toggleParentView: toggleParentView)
    }

    func resolve(_ dependencies: [String: Any]) -> PluginRoot? {
        guard let renderer = dependencies[String(describing: WidgetRenderer.self)] as? WidgetRenderer else {
            assertionFailure("Failed to resolve dependency for WidgetRenderer")
            return nil
        }
        guard let widgetPauser = dependencies[String(describing: WidgetPauser.self)] as? WidgetPauser else {
            assertionFailure("Failed to resolve dependency for WidgetPauser")
            return nil
        }
        guard let widgetCrossSessionPauser = dependencies[String(describing: WidgetCrossSessionPauser.self)] as? WidgetCrossSessionPauser else {
            assertionFailure("Failed to resolve dependency for WidgetCrossSessionPauser")
            return nil
        }

        guard let eventRecorder = dependencies[String(describing: EventRecorder.self)] as? EventRecorder else {
            assertionFailure("Failed to resolve dependency for EventRecorder")
            return nil
        }

        return WidgetToggleManager(renderer: renderer, widgetPauser: widgetPauser, widgetCrossSessionPauser: widgetCrossSessionPauser, eventRecorder: eventRecorder, params: self)
    }
}
