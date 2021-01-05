//
//  PromiseQueue.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 8/13/20.
//

import Foundation

/// The purpose behind the `PromiseQueue` class is to be able to run Promises in a serial order
class PromiseQueue {
    private let queue: DispatchQueue
    private var semaphore: DispatchSemaphore
    private var internalCount: Int = 0 // use this to see how many promises are enqued
    var count: Int {
        return internalCount
    }
    
    /// - Parameters:
    ///   - name: unique identifier of the DispatchQueue to be created
    ///   - maxConcurrentPromises: maximum amount of promises allowed to run at time
    init(name: String, maxConcurrentPromises: Int) {
        self.queue =  DispatchQueue(label: name, attributes: .concurrent)
        self.semaphore = DispatchSemaphore(value: maxConcurrentPromises)
    }

    func enque<T>(promiseTask: PromiseTask<T>) {
        internalCount += 1
        queue.async { [weak self] in
            guard let self = self else { return }
            
            _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
            promiseTask.run().always {
                self.internalCount -= 1
                self.semaphore.signal()
            }
        }
    }
}

/// This class is a wrapper class for a Promise which would then be enqueued into `PromiseQueue`
class PromiseTask<T> {
    private let loadedPromise: () -> Promise<T>

    init(promise: @escaping () -> Promise<T>) {
        self.loadedPromise = promise
    }

    /// Execute the loaded promise
    func run() -> Promise<T> {
        return loadedPromise()
    }
}
