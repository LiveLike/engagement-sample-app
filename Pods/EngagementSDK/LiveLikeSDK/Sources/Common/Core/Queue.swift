//
//  Queue.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/1/19.
//

import Foundation

/// A thread-safe queue.
class Queue<Element> {
    private var elements: [Element] = []
    private let syncQueue = DispatchQueue(label: "com.livelike.queueSync", attributes: .concurrent)

    func enqueue(element: Element) {
        syncQueue.async(flags: .barrier) {
            self.elements.append(element)
        }
    }
    
    func enqueueFromFront(element: Element){
        syncQueue.async(flags: .barrier) {
            self.elements.insert(element, at: 0)
        }
    }

    func dequeue() -> Element? {
        var element: Element?
        syncQueue.sync {
            if !self.elements.isEmpty {
                element = self.elements.first
                removeNext()
            }
        }
        return element
    }

    func peek() -> Element? {
        var element: Element?
        syncQueue.sync { element = self.elements.first }
        return element
    }

    var count: Int {
        var result: Int = 0
        syncQueue.sync { result = self.elements.count }
        return result
    }

    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        syncQueue.sync { result = self.elements.contains(where: predicate) }
        return result
    }

    /// Removes the next element in the queue (if element exists). This operation is thread-safe.
    internal func removeNext() {
        syncQueue.async(flags: .barrier) {
            if !self.elements.isEmpty {
                self.elements.remove(at: 0)
            }
        }
    }
}
