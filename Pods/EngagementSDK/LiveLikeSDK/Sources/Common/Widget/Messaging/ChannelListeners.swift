//
//  Listener.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-29.
//

import Foundation

/// A thread safe class for managing channel listeners.
///
/// A strong reference is maintained for each listener. Therefore for each
/// ```
/// addListener(_ listener: WidgetProxyInput, forChannel channel: String)
/// ```
/// a corresponding
/// ```
/// removeListener(_ listener: WidgetProxyInput, forChannel channel: String)
/// ```
/// is required, otherwise a memory leak could occur
class ChannelListeners {
    private var channelListeners = [String: [WidgetProxyInput]]()
    private let synchronizingQueue = DispatchQueue(label: "com.livelike.clientListenerSynchronizer", attributes: .concurrent)

    func addListener(_ listener: WidgetProxyInput, forChannel channel: String) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            if var listeners = self?.channelListeners[channel] {
                if listeners.contains(where: { $0 === listener }) { return }
                listeners.append(listener)
                self?.channelListeners[channel] = listeners
            } else {
                self?.channelListeners[channel] = [listener]
            }
        }
    }

    func removeListener(_ listener: WidgetProxyInput, forChannel channel: String) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            if var listeners = self?.channelListeners[channel] {
                listeners.removeAll(where: { $0 === listener })
                self?.channelListeners[channel] = listeners.isEmpty ? nil : listeners
            }
        }
    }

    func isEmpty(forChannel channel: String) -> Bool {
        var isEmpty = true
        synchronizingQueue.sync {
            if let listeners = channelListeners[channel] {
                isEmpty = listeners.isEmpty
            }
        }
        return isEmpty
    }

    func removeAll() {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            self?.channelListeners.removeAll()
        }
    }

    func publish(channel: String?, _ invocation: (WidgetProxyInput) -> Void) {
        synchronizingQueue.sync { [weak self] in
            guard let self = self else { return }
            if let channel = channel {
                guard let inputs = self.channelListeners[channel] else { return }
                for listener in inputs {
                    invocation(listener)
                }
            } else {
                for listener in channelListeners.values.flatMap({ $0 }) {
                    invocation(listener)
                }
            }
        }
    }
}
