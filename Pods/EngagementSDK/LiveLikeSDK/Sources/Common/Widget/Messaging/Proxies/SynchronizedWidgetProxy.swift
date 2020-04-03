//
//  SynchronizedWidgetProxy.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-21.
//

import UIKit

class SynchronizedWidgetProxy: WidgetProxy {
    /// Private
    private let queue = Queue<ClientEvent>()
    private var timer: DispatchSourceTimer?
    private var playerTimeSource: PlayerTimeSource?

    // The threshold at which the SDK can be ahead of the CMS before discarding "older" widgets
    private let delayThreshold: TimeInterval = .greatestFiniteMagnitude

    /// Internal
    var downStreamProxyInput: WidgetProxyInput?

    init(playerTimeSource: PlayerTimeSource?) {
        self.playerTimeSource = playerTimeSource
        timer = processQueueForEligibleScheduledEvent()
    }

    deinit {
        timer?.cancel()
    }

    func publish(event: ClientEvent) {
        queue.enqueue(element: event)
    }
}

// MARK: - Private

private extension SynchronizedWidgetProxy {
    /// Intervally checks the queue for a eligible event to be published
    /// An event is eligible if it has a minimumScheduleTime and is less
    /// than the currentTime
    ///
    /// - Returns: The `DispatchSourceTimer`
    func processQueueForEligibleScheduledEvent() -> DispatchSourceTimer {
        self.timer?.cancel()
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let event = self.queue.peek() else { return }

            // Send widget immediately if widget is unscheduled or no time source.
            if event.minimumScheduledTime == nil || self.playerTimeSource?() == nil {
                self.downStreamProxyInput?.publish(event: event)
                self.queue.removeNext()
            }

            guard let minimumScheduledTime = event.minimumScheduledTime else { return }
            guard let playerTimeSource = self.playerTimeSource?() else { return }

            // Discard widget if it doesn't meet the delay threshold
            if (playerTimeSource - minimumScheduledTime) > self.delayThreshold {
                self.downStreamProxyInput?.discard(event: event, reason: .invalidPublishDate)
                self.queue.removeNext()
                return
            }

            // Send widget when timeSource has passed minimumScheduledTime
            if minimumScheduledTime <= playerTimeSource {
                self.downStreamProxyInput?.publish(event: event)
                self.queue.removeNext()
            }
        }
        timer.resume()
        return timer
    }
}
