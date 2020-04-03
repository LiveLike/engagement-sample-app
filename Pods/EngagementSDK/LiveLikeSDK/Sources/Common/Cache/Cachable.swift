//
//  Cachable.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-15.
//

import Foundation

protocol Cachable {
    static func decode(_ data: Data) -> Self?
    func encode() -> Data?
}
