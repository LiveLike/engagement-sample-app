//
//  WidgetPauseDialogTrigger.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/6/19.
//

import Foundation

class WidgetPauseDialogTrigger {
    private let renderer: WidgetRenderer
    private let dismissWidgetFactory: WidgetPauseDialogViewController.Factory
    private let triggerThreshold: Int
    private let dismissWidgetTutorial: Tutorial
    private var consecutiveDismissCount: Int = 0

    init(renderer: WidgetRenderer, dismissWidgetFactory: WidgetPauseDialogViewController.Factory, triggerThreshold: Int, dismissWidgetTutorial: Tutorial) {
        self.renderer = renderer
        self.dismissWidgetFactory = dismissWidgetFactory
        self.triggerThreshold = triggerThreshold
        self.dismissWidgetTutorial = dismissWidgetTutorial
        self.renderer.subscribe(widgetRendererDelegate: self)
    }

    deinit {
        // Currently cuasing a bad access crash because asynchronously removing self
        // Need to revisit Listener class to remove a weak listener
        // self.renderer.widgetRendererListeners.removeListener(self)
    }
}

extension WidgetPauseDialogTrigger: WidgetRendererDelegate {
    func widgetWillStopRendering(widget: WidgetViewModel) {}
    func widgetDidStartRendering(widget: WidgetController) {}

    func widgetDidStopRendering(widget: WidgetViewModel, dismissAction: DismissAction) {
        // don't count dismisses of the dismiss widget
        guard widget.kind != WidgetKind.dismissToggle else { return }
        // only count dismisses triggered by user
        guard dismissAction.userDismissed else { return }

        consecutiveDismissCount += 1

        if consecutiveDismissCount >= triggerThreshold {
            delay(1) { // give some time between last widget dismissed and this widget
                self.renderer.displayWidget(handler: { (theme) -> WidgetController in
                    self.dismissWidgetFactory.create(theme: theme, trigger: .passThreshold(threshold: self.triggerThreshold))
                })
                self.dismissWidgetTutorial.tutorialComplete()
            }
        }
    }
}
