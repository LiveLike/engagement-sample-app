//
//  MemoryCache.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-15.
//

import Foundation

final class MemoryCache: CacheProtocol {
    let cache = NSCache<AnyObject, AnyObject>()

    func has(key: String) -> Bool {
        return cache.object(forKey: key as AnyObject) != nil
    }

    func set<T>(object: T, key: String, completion: (() -> Void)?) where T: Cachable {
        cache.setObject(object as AnyObject, forKey: key as AnyObject)
        completion?()
    }

    func get<T>(key: String, completion: @escaping (T?) -> Void) where T: Cachable {
        let object = cache.object(forKey: key as AnyObject)
        completion(object as? T)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
