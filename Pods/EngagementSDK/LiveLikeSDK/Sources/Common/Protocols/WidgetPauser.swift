//
//  WidgetPauser.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/7/19.
//

import Foundation

protocol WidgetPauser: AnyObject {
    var widgetPauseStatus: PauseStatus { get }
    func setDelegate(_ delegate: PauseDelegate)
    func removeDelegate(_ delegate: PauseDelegate)
    func pauseWidgets()
    func resumeWidgets()
}

protocol WidgetCrossSessionPauser {
    func pauseWidgetsForAllContentSessions()
    func resumeWidgetsForAllContentSessions()
}

protocol PauseDelegate: AnyObject {
    func pauseStatusDidChange(status: PauseStatus)
}
