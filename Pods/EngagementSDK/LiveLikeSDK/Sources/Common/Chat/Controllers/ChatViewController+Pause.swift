//
//  ChatViewController+Pause.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/22/19.
//

import Foundation

public extension ChatViewController {
    
    @available(*, deprecated, message: "Please use `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this")
    func pause() {
        eventRecorder?.record(.chatPauseStatusChanged(previousStatus: .unpaused,
                                                     newStatus: .paused,
                                                     secondsInPreviousStatus: Date().timeIntervalSince(timeChatPauseStatusChanged)))
        messageViewController.shouldShowIncomingMessages = false
        timeChatPauseStatusChanged = Date()
        log.info("Chat was paused.")
    }

    @available(*, deprecated, message: "Please use `shouldShowIncomingMessages` and `isChatInputVisible` to achieve this")
    func resume() {
        eventRecorder?.record(.chatPauseStatusChanged(previousStatus: .paused,
                                                     newStatus: .unpaused,
                                                     secondsInPreviousStatus: Date().timeIntervalSince(timeChatPauseStatusChanged)))
        messageViewController.shouldShowIncomingMessages = true
        log.info("Chat has resumed from pause.")
    }
}
