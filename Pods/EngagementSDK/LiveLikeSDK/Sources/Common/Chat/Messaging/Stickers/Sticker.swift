//
//  Sticker.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-21.
//

import Foundation

struct Sticker: Decodable, Equatable {
    let id: String
    let url: URL
    let packId: String
    let packUrl: URL
    let packName: String
    let shortcode: String
    let file: URL
}
