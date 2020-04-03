//
//  PubSubID.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

struct PubSubID: Equatable, Hashable {
    let internalID: AnyHashable

    init(_ hashable: AnyHashable) {
        self.internalID = hashable
    }

    static func == (lhs: PubSubID, rhs: PubSubID) -> Bool {
        return lhs.internalID == rhs.internalID
    }
}
