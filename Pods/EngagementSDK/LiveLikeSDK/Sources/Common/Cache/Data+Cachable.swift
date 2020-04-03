//
//  Data+Cachable.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-25.
//

import Foundation

extension Data: Cachable {
    typealias CacheType = Data

    static func decode(_ data: Data) -> Data? {
        return data
    }

    func encode() -> Data? {
        return self
    }
}
