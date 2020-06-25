//
//  UIImageView+Animation.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-25.
//

import UIKit

extension GIFImageView {
    func setImage(url: URL, isRetry: Bool = false) {
        EngagementSDK.mediaRepository.getImage(url: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                switch success.imageType {
                case .gif:
                    self.animate(withGIFData: success.imageData)
                default:
                    self.image = success.image
                }
            case .failure(let error):
                log.error(error)
            }
        }
    }
}
