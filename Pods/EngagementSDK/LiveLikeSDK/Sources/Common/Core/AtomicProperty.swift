//
//  AtomicProperty.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/5/20.
//

import Foundation

final class ReadWriteLock {
    private var rwlock: pthread_rwlock_t = {
        var rwlock = pthread_rwlock_t()
        pthread_rwlock_init(&rwlock, nil)
        return rwlock
    }()

    func writeLock() {
        pthread_rwlock_wrlock(&rwlock)
    }

    func readLock() {
        pthread_rwlock_rdlock(&rwlock)
    }

    func unlock() {
        pthread_rwlock_unlock(&rwlock)
    }
}

@propertyWrapper
class ReadWriteAtomic<Value> {
    private var underlyingFoo: Value
    private let lock = ReadWriteLock()

    init(wrappedValue value: Value) {
        self.underlyingFoo = value
    }

    var wrappedValue: Value {
        get {
            lock.readLock()
            let value = underlyingFoo
            lock.unlock()
            return value
        }
        set {
            lock.writeLock()
            underlyingFoo = newValue
            lock.unlock()
        }
    }
}
