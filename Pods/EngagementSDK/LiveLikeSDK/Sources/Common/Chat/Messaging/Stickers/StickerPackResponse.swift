//
//  StickerPackResponse.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-21.
//

import Foundation

struct StickerPackResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [StickerPack]
}
