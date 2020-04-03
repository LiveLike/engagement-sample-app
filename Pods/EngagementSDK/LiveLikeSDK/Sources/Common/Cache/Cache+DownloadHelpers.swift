//
//  Cache+DownloadHelpers.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/7/19.
//

import UIKit

extension Cache {
    func downloadAndCacheImages(urls: [URL], completion: (() -> Void)?) {
        let uncachedUrls = urls.filter { !has(key: $0.absoluteString) }
        let imagePromises = uncachedUrls.map { url in
            UIImage.download(url: url).then { [weak self] data in
                self?.set(object: data, key: url.absoluteString, completion: nil)
            }
        }

        firstly {
            Promises.all(imagePromises)
        }.then { _ in
            completion?()
        }.catch {
            log.error($0.localizedDescription)
        }
    }
}
