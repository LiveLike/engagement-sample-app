//
//  Cache.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-15.
//

import Foundation

final class Cache: CacheProtocol {
    static let shared = Cache()

    // MARK: Private properties

    let memoryCache = MemoryCache()
    let diskCache = DiskCache()

    func has(key: String) -> Bool {
        return memoryCache.has(key: key) || diskCache.has(key: key)
    }

    func set<T>(object: T, key: String, completion: (() -> Void)?) where T: Cachable {
        memoryCache.set(object: object, key: key) { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            self.diskCache.set(object: object, key: key, completion: {
                completion?()
            })
        }
    }

    func get<T>(key: String, completion: @escaping (T?) -> Void) where T: Cachable {
        memoryCache.get(key: key) { [weak self] (object: T?) in
            guard let self = self else {
                completion(nil)
                return
            }
            if let object = object {
                completion(object)
                return
            }

            self.diskCache.get(key: key, completion: { [weak self] (object: T?) in
                guard let self = self else {
                    completion(nil)
                    return
                }
                guard let object = object else {
                    log.error(CacheError.nilObjectFoundInCache)
                    completion(nil)
                    return
                }
                self.memoryCache.set(object: object, key: key, completion: nil)
                completion(object)
            })
        }
    }

    func clear() {
        memoryCache.clear()
        diskCache.clear()
    }
}

// MARK: Promises

extension Cache {
    func set<T>(object: T, key: String) -> Promise<T> where T: Cachable {
        return Promise { [weak self] fulfill, reject in
            guard let self = self else {
                reject(CacheError.promiseRejectedDueToNilSelf)
                return
            }
            self.set(object: object, key: key, completion: {
                fulfill(object)
            })
        }
    }

    func get<T>(key: String) -> Promise<T> where T: Cachable {
        return Promise { [weak self] fulfill, reject in
            guard let self = self else {
                reject(CacheError.promiseRejectedDueToNilSelf)
                return
            }
            self.get(key: key, completion: { (object: T?) in
                guard let object = object else {
                    reject(CacheError.nilObjectFoundInCache)
                    return
                }
                fulfill(object)
            })
        }
    }
}
