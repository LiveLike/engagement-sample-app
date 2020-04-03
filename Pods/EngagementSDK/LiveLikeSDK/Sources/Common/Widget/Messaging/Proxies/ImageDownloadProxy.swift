//
//  AssetDownloadProxy.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/26/19.
//

import UIKit

/// A proxy that downloads images before publishing the client event downstream
class ImageDownloadProxy: WidgetProxy {
    var downStreamProxyInput: WidgetProxyInput?

    private let cache = Cache.shared

    func publish(event: ClientEvent) {
        let completion = { [weak self] in
            guard let self = self else { return }
            self.downStreamProxyInput?.publish(event: event)
        }

        switch event {
        case let .imagePredictionCreated(payload):
            cache.downloadAndCacheImages(urls: payload.options.map { $0.imageUrl }, completion: completion)
        case let .imagePredictionFollowUp(payload, _):
            cache.downloadAndCacheImages(urls: payload.options.map { $0.imageUrl }, completion: completion)
        case let .imagePollCreated(payload):
            cache.downloadAndCacheImages(urls: payload.options.map { $0.imageUrl }, completion: completion)
        case let .imageQuizCreated(payload):
            cache.downloadAndCacheImages(urls: payload.choices.map { $0.imageUrl }, completion: completion)
        case let .alertCreated(payload):
            if let url = payload.imageUrl {
                cache.downloadAndCacheImages(urls: [url], completion: completion)
            } else {
                downStreamProxyInput?.publish(event: event)
            }
        case let .imageSliderCreated(payload):
            cache.downloadAndCacheImages(urls: payload.options.map { $0.imageUrl }, completion: completion)
        case let .cheerMeterCreated(payload):
            cache.downloadAndCacheImages(urls: payload.options.map { $0.imageUrl }, completion: completion)
        default:
            downStreamProxyInput?.publish(event: event)
        }
    }
}
