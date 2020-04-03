//
//  CacheProtocol.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-15.
//

import Foundation

protocol CacheProtocol {
    func has(key: String) -> Bool
    func set<T: Cachable>(object: T, key: String, completion: (() -> Void)?)
    func get<T: Cachable>(key: String, completion: @escaping (_ object: T?) -> Void)
    func clear()
}
