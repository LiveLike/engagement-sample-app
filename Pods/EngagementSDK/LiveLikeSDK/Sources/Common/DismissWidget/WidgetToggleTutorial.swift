//
//  WidgetToggleTutorial.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/12/19.
//

import Foundation

/// A tutorial that teaches the user about how to toggle widgets using the toggle button
class WidgetToggleTutorial: Tutorial {
    private let tutorialCompleteUserDefaultsKey: String = "EngagementSDK.dismissWidgetTutorialComplete"
    private var permanentDismissTrigger: WidgetPauseDialogTrigger?
    private let widgetToggle: WidgetToggleViewController

    var isTutorialComplete: Bool

    init(renderer: WidgetRenderer, dismissWidgetFactory: WidgetPauseDialogViewController.Factory, triggerThreshold: Int, widgetToggle: WidgetToggleViewController) {
        self.widgetToggle = widgetToggle
        isTutorialComplete = UserDefaults.standard.bool(forKey: tutorialCompleteUserDefaultsKey)
        if !isTutorialComplete {
            permanentDismissTrigger = WidgetPauseDialogTrigger(renderer: renderer,
                                                               dismissWidgetFactory: dismissWidgetFactory,
                                                               triggerThreshold: triggerThreshold,
                                                               dismissWidgetTutorial: self)
        } else {
            widgetToggle.show()
        }
    }

    func tutorialComplete() {
        isTutorialComplete = true
        UserDefaults.standard.set(true, forKey: tutorialCompleteUserDefaultsKey)
        permanentDismissTrigger = nil
        widgetToggle.show()
    }
}

protocol Tutorial {
    var isTutorialComplete: Bool { get }
    func tutorialComplete()
}
