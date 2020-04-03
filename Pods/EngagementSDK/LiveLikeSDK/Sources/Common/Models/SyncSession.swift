//
//  SyncSession.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-14.
//

import Foundation

struct SyncSession: Decodable {
    let pin: String
    let syncChannel: String
    let connectTimeout: TimeInterval

    enum CodingKeys: String, CodingKey {
        case pin
        case syncChannel
        case connectTimeout
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pin = try container.decode(String.self, forKey: .pin)
        syncChannel = try container.decode(String.self, forKey: .syncChannel)
        let iso8601Duration = try container.decode(String.self, forKey: .connectTimeout)
        connectTimeout = iso8601Duration.timeIntervalFromISO8601Duration() ?? 180 // use a default of 3 minutes if this parsing fails
    }
}
