//
//  StickerPack.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-21.
//

import UIKit

struct StickerPack: Decodable {
    let id: String
    let url: URL?
    let name: String
    let file: URL
    let stickers: [Sticker]
}

extension StickerPack {
    static var identifier: String {
        return "chat_recent_stickers_tab"
    }

    static func recentStickerPacks(from stickers: [Sticker]) -> [StickerPack] {
        var stickerPack = [StickerPack]()

        let fileURL = "file://chat_recent_stickers_tab.local"

        if let image = UIImage(named: identifier, in: Bundle(for: ChatViewController.self), compatibleWith: nil),
            let imageData = image.encode(),
            let url = URL(string: fileURL) {
            Cache.shared.set(object: imageData, key: fileURL, completion: nil)
            stickerPack.append(StickerPack(id: identifier, url: nil, name: identifier, file: url, stickers: stickers))
        }
        return stickerPack
    }
}

enum StickerPackType {
    case normal
    case recent
}
