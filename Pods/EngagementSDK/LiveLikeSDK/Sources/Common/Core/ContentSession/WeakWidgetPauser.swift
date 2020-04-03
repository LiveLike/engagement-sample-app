//
//  WeakWidgetPauser.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/18/19.
//

import Foundation

/**
 Weak box for a WidgetPauser.

 Use case:
 Allows the ContentSession to maintain a strong reference to the plugin while
 avoiding a retain cycle when passing the ContentSession(WidgetPauser) as a dependency
 */
class WeakWidgetPauser: WidgetPauser, PauseDelegate {
    weak var widgetPauser: WidgetPauser?

    init(_ widgetPauser: WidgetPauser) {
        self.widgetPauser = widgetPauser
        widgetPauseStatus = widgetPauser.widgetPauseStatus
        self.widgetPauser?.setDelegate(self)
    }

    var widgetPauseStatus: PauseStatus

    func setDelegate(_ delegate: PauseDelegate) {
        widgetPauser?.setDelegate(delegate)
    }

    func removeDelegate(_ delegate: PauseDelegate) {
        widgetPauser?.removeDelegate(delegate)
    }

    func pauseWidgets() {
        widgetPauser?.pauseWidgets()
    }

    func resumeWidgets() {
        widgetPauser?.resumeWidgets()
    }

    func pauseStatusDidChange(status: PauseStatus) {
        widgetPauseStatus = status
    }
}
