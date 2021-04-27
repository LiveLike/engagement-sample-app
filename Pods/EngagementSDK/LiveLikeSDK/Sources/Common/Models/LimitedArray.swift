//
//  LimitedArray.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-13.
//

import Foundation

/// an array-like struct that has a fixed maximum capacity
/// any element over the maximum allowed size gets discarded
struct LimitedArray<T: Equatable> {
    private(set) var storage: [T] = []
    public let maxSize: Int

    /// creates an empty array
    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    /// takes the max N elements from the given collection
    init<S: Sequence>(from other: S, maxSize: Int) where S.Element == T {
        self.maxSize = maxSize
        storage = Array(other.prefix(maxSize))
    }

    /// adds a new item to the array, does nothing if the array has reached its maximum capacity
    /// returns a bool indicated the operation success
    @discardableResult mutating func append(_ item: T) -> Bool {
        if storage.count < maxSize {
            storage.append(item)
            return true
        } else {
            return false
        }
    }

    /// inserts an item at the specified position. if this would result in
    /// the array exceeding its maxSize, the extra element are dropped
    mutating func insert(_ item: T, at index: Int) {
        if let index = storage.firstIndex(of: item) {
            storage.remove(at: index)
        }
        storage.insert(item, at: index)
        if storage.count > maxSize {
            storage.remove(at: maxSize)
        }
    }

    mutating func removeAll() {
        storage.removeAll()
    }
}

// let's benefit all the awesome operations like map, flatMap, reduce, filter, etc
extension LimitedArray: MutableCollection {
    var startIndex: Int { return storage.startIndex }
    var endIndex: Int { return storage.endIndex }
    
    subscript(_ index: Int) -> T {
        get { return storage[index] }
        set { storage[index] = newValue }
    }

    func index(after i: Int) -> Int {
        return storage.index(after: i)
    }
}
