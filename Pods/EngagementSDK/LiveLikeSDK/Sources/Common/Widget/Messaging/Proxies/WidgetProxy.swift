//
//  WidgetProxy.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-21.
//

import Foundation

typealias WidgetProxy = WidgetProxyInput & WidgetProxyOutput

protocol WidgetProxyInput: AnyObject {
    func publish(event: ClientEvent)
    func discard(event: ClientEvent, reason: DiscardedReason)
    func connectionStatusDidChange(_ status: ConnectionStatus)
    func error(_ error: Error)
}

protocol WidgetProxyOutput: AnyObject {
    var downStreamProxyInput: WidgetProxyInput? { get set }
}

extension WidgetProxyInput where Self: WidgetProxyOutput {
    func error(_ error: Error) {
        downStreamProxyInput?.error(error)
    }

    func discard(event: ClientEvent, reason: DiscardedReason) {
        downStreamProxyInput?.discard(event: event, reason: reason)
    }

    func connectionStatusDidChange(_ status: ConnectionStatus) {
        downStreamProxyInput?.connectionStatusDidChange(status)
    }
}

extension WidgetProxyOutput {
    func addProxy(_ proxy: () -> WidgetProxy) -> WidgetProxy {
        let input = proxy()
        downStreamProxyInput = input
        return input
    }

    func addProxy(_ proxy: () -> WidgetQueue) -> WidgetQueue {
        let input = proxy()
        downStreamProxyInput = input
        return input
    }
}
