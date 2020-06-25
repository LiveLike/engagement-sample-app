//
//  ApplicationConfiguration.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-03.
//

import Foundation

struct Applications: Decodable {
    let results: [ApplicationConfiguration]
}

struct ApplicationConfiguration: Decodable {
    let name: String
    let clientId: String
    let pubnubPublishKey: String?
    let pubnubSubscribeKey: String?
    let sessionsUrl: URL
    let profileUrl: URL
    let stickerPacksUrl: URL
    let programsUrl: URL
    let programDetailUrlTemplate: String
    let chatRoomDetailUrlTemplate: String
    let mixpanelToken: String?
    let analyticsProperties: [String: String]
    let pubnubOrigin: String?
    let organizationId: String
    let organizationName: String
    let createChatRoomUrl: String
    
}
