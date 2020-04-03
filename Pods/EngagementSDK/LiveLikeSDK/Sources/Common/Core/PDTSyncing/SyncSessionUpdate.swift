//
//  SyncSessionUpdate.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-16.
//

import Foundation

struct SyncSessionUpdate: Encodable {
    let event: EventName
    let payload: Update

    struct Update: Encodable {
        let programDateTime: Date
    }
}
