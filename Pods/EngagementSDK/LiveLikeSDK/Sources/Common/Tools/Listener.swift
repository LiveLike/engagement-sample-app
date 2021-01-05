//
//  Listener.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-15.
//

import Foundation

/// A thread safe class for managing an array of objects of a given type. The sequence holds
/// weak references to the contained objects, allowing them to be deallocated and
/// removed automatically. Order is not respected
class Listener<T> {
    private let listeners: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private let synchronizingQueue: DispatchQueue

    init(dispatchQueueLabel: String = "com.livelike.listenerSynchronizer") {
        synchronizingQueue = DispatchQueue(label: dispatchQueueLabel, attributes: .concurrent)
    }

    /// Adds element to the set, if the element already exists in the set,
    /// this has no effect.
    ///
    /// - Parameter listener: The element to added
    func addListener(_ listener: T) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            self?.listeners.add(listener as AnyObject)
        }
    }

    /// Removes an element from the set if it's contained in the set
    ///
    /// - Parameter listener: the element to be removed
    func removeListener(_ listener: T) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            self?.listeners.remove(listener as AnyObject)
        }
    }

    /// Removes all elements in the set
    func removeAll() {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            self?.listeners.removeAllObjects()
        }
    }

    func isEmpty() -> Bool {
        var isEmpty = true
        synchronizingQueue.sync { [weak self] in
            guard let self = self else { return }
            isEmpty = self.listeners.allObjects.isEmpty
        }
        return isEmpty
    }

    /// Invokes a closure on each element contained in the set
    ///
    /// e.g.
    /// ```
    /// listener.publish({ $0.someFunction() })
    /// ```
    /// - Parameter invocation: The closure to be invoked on each element
    func publish(_ invocation: (T) -> Void) {
        synchronizingQueue.sync { [weak self] in
            guard let self = self else { return }
            for listener in self.listeners.allObjects {
                invocation(listener as! T) // swiftlint:disable:this force_cast
            }
        }
    }
    
}
