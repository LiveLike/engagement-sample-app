//
//  WidgetLoggerProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/6/19.
//

import Foundation

// Prints information to the log
class WidgetLoggerProxy: WidgetProxy {
    var downStreamProxyInput: WidgetProxyInput?
    private var playerTimeSource: PlayerTimeSource?

    init(playerTimeSource: PlayerTimeSource?) {
        self.playerTimeSource = playerTimeSource
    }

    func publish(event: ClientEvent) {
        var message: String = "Widget"

        if let minimumScheduledTime = event.minimumScheduledTime, let playerTimeSource = playerTimeSource?() {
            message.append(" [widget \(DateFormatter.currentTimeZoneTime.string(from: Date(timeIntervalSince1970: minimumScheduledTime))) | \(DateFormatter.currentTimeZoneTime.string(from: Date(timeIntervalSince1970: playerTimeSource))) video]")
        }

        log.info(message)

        downStreamProxyInput?.publish(event: event)
    }
}
