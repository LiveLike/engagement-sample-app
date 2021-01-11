//
//  ProgramDetail.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-03.
//

import Foundation

struct ProgramsResource: Decodable {
    let results: [ProgramDetailResource]
}

struct ProgramDetailResource: Decodable {
    let id: String
    let title: String
    let widgetsEnabled: Bool
    let chatEnabled: Bool
    let subscribeChannel: String?
    let syncSessionsUrl: URL
    let rankUrl: URL
    let reactionPacksUrl: URL?
    let defaultChatRoom: ChatRoomResource?
    let timelineUrl: URL
    let leaderboards: [LeaderboardResource]
    let rewardItems: [RewardItemResource]

    /// Exclusively for CMS and Demo use
    let streamUrl: String?
}
