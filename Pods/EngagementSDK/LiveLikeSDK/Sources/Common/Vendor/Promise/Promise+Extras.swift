/*
 The MIT License (MIT)

 Copyright (c) 2016 Soroush Khanlou

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
#if os(Linux)
    import Dispatch
#endif
// swiftlint:disable all
struct PromiseCheckError: Error {}

enum Promises {
    /// Wait for all the promises you give it to fulfill, and once they have, fulfill itself
    /// with the array of all fulfilled values.
    static func all<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
        return Promise<[T]>(work: { fulfill, reject in
            guard !promises.isEmpty else { fulfill([]); return }
            for promise in promises {
                promise.then { _ in
                    if !promises.contains(where: { $0.isRejected || $0.isPending }) {
                        fulfill(promises.compactMap { $0.value })
                    }
                }.catch { error in
                    reject(error)
                }
            }
        })
    }

    /// Resolves itself after some delay.
    /// - parameter delay: In seconds
    static func delay(_ delay: TimeInterval) -> Promise<Void> {
        return Promise<Void>(work: { fulfill, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                fulfill(())
            }
        })
    }

    /// This promise will be rejected after a delay.
    static func timeout<T>(_ timeout: TimeInterval) -> Promise<T> {
        return Promise<T>(work: { _, reject in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                reject(NSError(domain: "com.khanlou.Promise", code: -1111, userInfo: [NSLocalizedDescriptionKey: "Timed out"]))
            }
        })
    }

    /// Fulfills or rejects with the first promise that completes
    /// (as opposed to waiting for all of them, like `.all()` does).
    static func race<T>(_ promises: [Promise<T>]) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
            guard !promises.isEmpty else { fatalError() }
            for promise in promises {
                promise.then(fulfill, reject)
            }
        })
    }

    static func retry<T>(count: Int, delay: TimeInterval, generate: @escaping () -> Promise<T>) -> Promise<T> {
        if count <= 0 {
            return generate()
        }
        return Promise<T>(work: { fulfill, reject in
            generate().recover { _ in
                self.delay(delay).then {
                    retry(count: count - 1, delay: delay, generate: generate)
                }
            }.then(fulfill).catch(reject)
        })
    }

    static func kickoff<T>(_ block: @escaping () throws -> Promise<T>) -> Promise<T> {
        return Promise(value: ()).then(block)
    }

    static func kickoff<T>(_ block: @escaping () throws -> T) -> Promise<T> {
        do {
            return try Promise(value: block())
        } catch {
            return Promise(error: error)
        }
    }

    static func zip<T, U>(_ first: Promise<T>, _ second: Promise<U>) -> Promise<(T, U)> {
        return Promise<(T, U)>(work: { fulfill, reject in
            let resolver: (Any) -> Void = { _ in
                if let firstValue = first.value, let secondValue = second.value {
                    fulfill((firstValue, secondValue))
                }
            }
            first.then(resolver, reject)
            second.then(resolver, reject)
        })
    }

    // The following zip functions have been created with the
    // "Zip Functions Generator" playground page. If you need variants with
    // more parameters, use it to generate them.

    /// Zips 3 promises of different types into a single Promise whose
    /// type is a tuple of 3 elements.
    static func zip<T1, T2, T3>(_ p1: Promise<T1>, _ p2: Promise<T2>, _ last: Promise<T3>) -> Promise<(T1, T2, T3)> {
        return Promise<(T1, T2, T3)>(work: { (fulfill: @escaping ((T1, T2, T3)) -> Void, reject: @escaping (Error) -> Void) in
            let zipped: Promise<(T1, T2)> = zip(p1, p2)

            func resolver() {
                if let zippedValue = zipped.value, let lastValue = last.value {
                    fulfill((zippedValue.0, zippedValue.1, lastValue))
                }
            }
            zipped.then({ _ in resolver() }, reject)
            last.then({ _ in resolver() }, reject)
        })
    }

    /// Zips 4 promises of different types into a single Promise whose
    /// type is a tuple of 4 elements.
    static func zip<T1, T2, T3, T4>(_ p1: Promise<T1>, _ p2: Promise<T2>, _ p3: Promise<T3>, _ last: Promise<T4>) -> Promise<(T1, T2, T3, T4)> {
        return Promise<(T1, T2, T3, T4)>(work: { (fulfill: @escaping ((T1, T2, T3, T4)) -> Void, reject: @escaping (Error) -> Void) in
            let zipped: Promise<(T1, T2, T3)> = zip(p1, p2, p3)

            func resolver() {
                if let zippedValue = zipped.value, let lastValue = last.value {
                    fulfill((zippedValue.0, zippedValue.1, zippedValue.2, lastValue))
                }
            }
            zipped.then({ _ in resolver() }, reject)
            last.then({ _ in resolver() }, reject)
        })
    }

    /// Zips 5 promises of different types into a single Promise whose
    /// type is a tuple of 5 elements.
    static func zip<T1, T2, T3, T4, T5>(_ p1: Promise<T1>, _ p2: Promise<T2>, _ p3: Promise<T3>, _ p4: Promise<T4>, _ last: Promise<T5>) -> Promise<(T1, T2, T3, T4, T5)> {
        return Promise<(T1, T2, T3, T4, T5)>(work: { (fulfill: @escaping ((T1, T2, T3, T4, T5)) -> Void, reject: @escaping (Error) -> Void) in
            let zipped: Promise<(T1, T2, T3, T4)> = zip(p1, p2, p3, p4)

            func resolver() {
                if let zippedValue = zipped.value, let lastValue = last.value {
                    fulfill((zippedValue.0, zippedValue.1, zippedValue.2, zippedValue.3, lastValue))
                }
            }
            zipped.then({ _ in resolver() }, reject)
            last.then({ _ in resolver() }, reject)
        })
    }
}

extension Promise {
    func addTimeout(_ timeout: TimeInterval) -> Promise<Value> {
        return Promises.race(Array([self, Promises.timeout(timeout)]))
    }

    @discardableResult
    func always(on queue: ExecutionContext = DispatchQueue.main, _ onComplete: @escaping () -> Void) -> Promise<Value> {
        return then(on: queue, { _ in
            onComplete()
        }, { _ in
            onComplete()
        })
    }

    func recover(_ recovery: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
        return Promise(work: { fulfill, reject in
            self.then(fulfill).catch { error in
                do {
                    try recovery(error).then(fulfill, reject)
                } catch {
                    reject(error)
                }
            }
        })
    }

    func ensure(_ check: @escaping (Value) -> Bool) -> Promise<Value> {
        return then { (value: Value) -> Value in
            guard check(value) else {
                throw PromiseCheckError()
            }
            return value
        }
    }
    
    func asVoid() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.then { _ in
                fulfill(())
            }.catch {
                reject($0)
            }
        }
    }
}

#if !swift(>=4.1)
    internal extension Sequence {
        func compactMap<T>(_ fn: (Element) throws -> T?) rethrows -> [T] {
            return try flatMap { try fn($0).map { [$0] } ?? [] }
        }
    }
#endif

func firstly<T>(promiseGenerator: () -> Promise<T>) -> Promise<T> {
    return promiseGenerator()
}
