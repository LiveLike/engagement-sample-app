//
//  ProgramDetail.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-03.
//

import Foundation

struct Programs: Decodable {
    let results: [ProgramDetail]
}

struct ProgramDetail: Decodable {
    let id: String
    let title: String
    let widgetsEnabled: Bool
    let chatEnabled: Bool
    let subscribeChannel: String?
    let syncSessionsUrl: URL
    let rankUrl: URL
    let rewardsType: RewardsType
    let reportUrl: URL
    let reactionPacksUrl: URL?
    let defaultChatRoom: ChatRoomResource?

    /// Exclusively for CMS and Demo use
    let streamUrl: String?
}

enum RewardsType: String, Decodable, Equatable {
    case pointsOnly = "points"
    case pointsAndBadges = "badges"
    case noRewards = "none"
}
