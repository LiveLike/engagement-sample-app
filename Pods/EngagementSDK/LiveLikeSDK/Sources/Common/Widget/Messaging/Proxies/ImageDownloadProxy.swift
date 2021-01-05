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

    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository

    func publish(event: WidgetProxyPublishData) {
        switch event.clientEvent {
        case .widget(let widgetResource):
            switch widgetResource {
            case let .imagePredictionCreated(payload):
                mediaRepository.prefetchMedia(urls: payload.options.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            case let .imagePredictionFollowUp(payload):
                mediaRepository.prefetchMedia(urls: payload.options.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            case let .imagePollCreated(payload):
                mediaRepository.prefetchMedia(urls: payload.options.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            case let .imageQuizCreated(payload):
                mediaRepository.prefetchMedia(urls: payload.choices.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            case let .alertCreated(payload):
                if let url = payload.imageUrl {
                    mediaRepository.prefetchMedia(url: url) { [weak self] result in
                        self?.handlePrefetchResult(result: result, event: event)
                    }
                } else {
                    downStreamProxyInput?.publish(event: event)
                }
            case let .imageSliderCreated(payload):
                mediaRepository.prefetchMedia(urls: payload.options.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            case let .cheerMeterCreated(payload):
                mediaRepository.prefetchMedia(urls: payload.options.map{ $0.imageUrl }) { [weak self] result in
                    self?.handlePrefetchResult(result: result, event: event)
                }
            default:
                downStreamProxyInput?.publish(event: event)
            }
        default:
            downStreamProxyInput?.publish(event: event)
        }
    }
    
    private func handlePrefetchResult(result: Result<Bool, Error>, event: WidgetProxyPublishData) {
        // Always publish event even if prefetch fails
        self.downStreamProxyInput?.publish(event: event)
    }
}
