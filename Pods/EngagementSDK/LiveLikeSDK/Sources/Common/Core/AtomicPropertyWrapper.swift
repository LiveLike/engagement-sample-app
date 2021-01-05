//
//  AtomicPropertyWrapper.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 10/21/20.
//

import Foundation

@propertyWrapper
public class Atomic<Value> {
    private var storage: Value
    private var isolationQueue = DispatchQueue(label: "com.livelike.atomicQueue",
                                               attributes: .concurrent)
    
    public init(wrappedValue value: Value) {
        storage = value
    }
    
    public var wrappedValue: Value {
        get {
            var result: Value!
            isolationQueue.sync {
                result = storage
            }
            return result
        }
        set {
            isolationQueue.async(flags: .barrier) {
                self.storage = newValue
            }
        }
    }
}
