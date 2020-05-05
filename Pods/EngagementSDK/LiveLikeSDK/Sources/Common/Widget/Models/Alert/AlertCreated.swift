//
//  AlertCreated.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-20.
//

import Foundation

struct AlertCreated: Decodable {
    let id: String
    let createdAt: Date
    let timeout: Timeout
    let subscribeChannel: String
    let programId: String
    let programDateTime: Date?
    let kind: WidgetKind
    let url: URL
    var impressionUrl: URL?

    let linkLabel: String?
    let linkUrl: URL?
    let text: String?
    let title: String?
    let imageUrl: URL?
    var rewardsUrl: URL?
    let customData: String?
    let animationTimerAsset: String = "timer"
}
