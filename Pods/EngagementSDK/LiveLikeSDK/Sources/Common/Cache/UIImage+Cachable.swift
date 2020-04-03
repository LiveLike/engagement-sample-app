//
//  UIImage+Cachable.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-19.
//

import UIKit

extension UIImage: Cachable {
    typealias CacheType = UIImage

    static func decode(_ data: Data) -> Self? {
        let image = self.init(data: data)
        return image
    }

    func encode() -> Data? {
        return pngData()
    }
}
