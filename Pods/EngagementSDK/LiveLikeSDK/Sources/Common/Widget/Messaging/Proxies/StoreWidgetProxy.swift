//
//  ProcessedMessagingClient.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/1/19.
//

import Foundation

protocol WidgetProcessor: AnyObject {
    var isProcessing: Bool { get set }
}

/// Stores client events and only publishes
/// when the `processor` has finished processing
class StoreWidgetProxy: WidgetProxy, WidgetProcessor {
    /// Private
    private let queue = Queue<WidgetProxyPublishData>()

    /// Internal
    var downStreamProxyInput: WidgetProxyInput?
    var isProcessing = false {
        didSet {
            guard isProcessing == false else { return }
            guard let event = queue.dequeue() else { return }
            downStreamProxyInput?.publish(event: event)
        }
    }

    func publish(event: WidgetProxyPublishData) {
        if !isProcessing {
            downStreamProxyInput?.publish(event: event)
        } else {
            queue.enqueue(element: event)
        }
    }
    
    func addToFrontOfQueue(event: WidgetProxyPublishData){
        if !isProcessing {
            downStreamProxyInput?.publish(event: event)
        } else {
            queue.enqueueFromFront(element: event)
        }
    }
}
