//
//  UIImage+Download.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/26/19.
//

import UIKit

extension UIImage {
    enum UIImageDownloadError: Error {
        case error(description: String)
    }

    static func download(url: URL) -> Promise<Data> {
        return Promise<Data>(work: { fulfilled, rejected in
            EngagementSDK.networking.urlSession.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    rejected(UIImageDownloadError.error(description: error.debugDescription))
                    return
                }
                fulfilled(data)
            }.resume()

        })
    }
}
