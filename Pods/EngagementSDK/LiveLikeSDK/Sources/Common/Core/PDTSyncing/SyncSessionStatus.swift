//
//  File.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-15.
//

import Foundation

struct SyncSessionStatus: Decodable {
    enum Status: String, Codable {
        case ping
        case pong
        case connected
    }

    struct Payload: Encodable {
        let status: Status
    }

    struct Get: Decodable {
        let status: Status
        let pubnubPublishKey: String?
    }

    struct Post: Encodable {
        let event: EventName
        let payload: Payload
    }
}
