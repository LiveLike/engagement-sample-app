//
//  WidgetToggleManager.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/7/19.
//

import UIKit

class WidgetToggleManager: PluginRoot {
    private let unmuteViewController: WidgetToggleViewController
    private let dismissWidgetTutorial: WidgetToggleTutorial

    init(renderer: WidgetRenderer, widgetPauser: WidgetPauser, widgetCrossSessionPauser: WidgetCrossSessionPauser, eventRecorder: EventRecorder, params: WidgetToggle) {
        let dismissWidgetFactory = WidgetPauseDialogViewController.Factory(widgetPauser: widgetPauser, widgetCrossSessionPauser: widgetCrossSessionPauser, eventRecorder: eventRecorder)

        let unmuteDialogFactory = WidgetUnpauseDialogViewController.Factory(widgetCrossSessionPauser: widgetCrossSessionPauser)

        let unmuteViewController = WidgetToggleViewController(widgetPauser: widgetPauser, widgetRenderer: renderer, unmuteDialogFactory: unmuteDialogFactory, muteDialogFactory: dismissWidgetFactory, theme: params.theme, eventRecorder: eventRecorder)
        unmuteViewController.view.translatesAutoresizingMaskIntoConstraints = false
        params.toggleParentView.addSubview(unmuteViewController.view)
        unmuteViewController.view.constraintsFill(to: params.toggleParentView)
        self.unmuteViewController = unmuteViewController

        dismissWidgetTutorial = WidgetToggleTutorial(renderer: renderer,
                                                     dismissWidgetFactory: dismissWidgetFactory,
                                                     triggerThreshold: params.triggerThreshold,
                                                     widgetToggle: unmuteViewController)
    }
}
