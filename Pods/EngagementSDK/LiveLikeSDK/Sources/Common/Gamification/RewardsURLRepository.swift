//
//  RewardsURLRepository.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/9/19.
//

import Foundation

class RewardsURLRepo {
    private var rewardsURLByIDDict: [String: URL] = [:]

    func add(withID: String, rewardsURL: URL) {
        rewardsURLByIDDict[withID] = rewardsURL
    }

    func get(id: String) -> URL? {
        if rewardsURLByIDDict.keys.contains(id) {
            return rewardsURLByIDDict[id]
        }
        return nil
    }
}
