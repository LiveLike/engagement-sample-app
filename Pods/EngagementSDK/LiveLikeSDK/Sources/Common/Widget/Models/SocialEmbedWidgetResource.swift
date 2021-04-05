//
//  SocialEmbedWidgetResource.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 2/1/21.
//

import Foundation

struct SocialEmbedWidgetResource: Decodable {
    let items: [Item]
    let comment: String?
    
    let subscribeChannel: String
    let createdAt: Date
    let publishedAt: Date?
    let programDateTime: Date?
    let kind: WidgetKind
    let id: String
    let impressionUrl: URL?
    let timeout: Timeout
    let rewardsUrl: URL?
    let programId: String
    let customData: String?
    
    struct Item: Decodable {
        let id: String
        let url: URL
        let oembed: OEmbed
        
        //swiftlint:disable nesting
        struct OEmbed: Decodable {
            let html: String
            let providerName: String
        }
    }
}
