//
//  PauseProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/7/19.
//

import Foundation

/// This component maintains a list of pause Timeframes (relative to a timeSource)
/// Discards all non-scheduled messages during a pause
/// Discards all scheduled messages that were published during pauses in the past and present
class PauseWidgetProxy: WidgetProxy {
    var downStreamProxyInput: WidgetProxyInput?

    typealias Timeframe = (startTime: EpochTime, endTime: EpochTime)

    private var playerTimeSource: PlayerTimeSource?
    private var pauseStatus: PauseStatus
    private var currentPauseStartTime: EpochTime?
    private var pastPauseTimes: [Timeframe] = []

    init(playerTimeSource: PlayerTimeSource?, initialPauseStatus: PauseStatus) {
        self.playerTimeSource = playerTimeSource
        pauseStatus = initialPauseStatus
    }

    func publish(event: ClientEvent) {
        guard let playerTimeSource = playerTimeSource?() else {
            downStreamProxyInput?.publish(event: event)
            return
        }

        /// Discard non-scheduled events while paused
        if pauseStatus == .paused, event.minimumScheduledTime == nil {
            downStreamProxyInput?.discard(event: event, reason: .paused)
            return
        }
        /// Discard scheduled events during a current pause
        if pauseStatus == .paused, let publishTime = event.minimumScheduledTime {
            guard let pauseStartTime = currentPauseStartTime else {
                downStreamProxyInput?.discard(event: event, reason: .paused)
                return
            }
            let nowTime = playerTimeSource
            if publishTime.isBetween(pauseStartTime, nowTime) {
                downStreamProxyInput?.discard(event: event, reason: .paused)
                return
            }
        }

        /// Discard scheduled events during a past pause
        if let publishTime = event.minimumScheduledTime {
            for pauseTime in pastPauseTimes where publishTime.isBetween(pauseTime.startTime, pauseTime.endTime) {
                downStreamProxyInput?.discard(event: event, reason: .paused)
                return
            }
        }

        downStreamProxyInput?.publish(event: event)
    }
}

extension PauseWidgetProxy: PauseDelegate {
    func pauseStatusDidChange(status: PauseStatus) {
        let timeSource = playerTimeSource?()
        pauseStatus = status
        switch status {
        case .paused:
            currentPauseStartTime = timeSource
        case .unpaused:
            // if we're connecting after a pause then capture timeFrame
            guard let startTime = currentPauseStartTime else { return }
            guard let currentTime = timeSource else { return }
            let timeFrame: Timeframe = (startTime, currentTime)
            pastPauseTimes.append(timeFrame)
            currentPauseStartTime = nil
        }
    }
}

extension EpochTime {
    func isBetween(_ startTime: EpochTime, _ endTime: EpochTime) -> Bool {
        return self > startTime && self < endTime
    }
}
