//
//  UIImageView+Animation.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-25.
//

import UIKit

extension GIFImageView {
    func setImage(key: String, isRetry: Bool = false) {
        Cache.shared.get(key: key) { [weak self] (data: Data?) in

            guard let data = data, let imageType = data.imageType else {
                if isRetry {
                    return
                }

                if let imageURL = URL(string: key) {
                    Cache.shared.downloadAndCacheImages(urls: [imageURL], completion: {
                        self?.setImage(key: key, isRetry: true)
                    })
                }
                return
            }

            self?.setImage(data: data, imageType: imageType)
        }
    }

    private func setImage(data: Data, imageType: ImageType) {
        switch imageType {
        case .gif:
            animate(withGIFData: data)
        default:
            if let image = UIImage.decode(data) {
                self.image = image
            }
        }
    }
}
