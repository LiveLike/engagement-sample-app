//
//  PubSubService.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 11/27/19.
//

import Foundation

/// Represents a publish/subscribe networking service
protocol PubSubService {
    func subscribe(_ channel: String) -> PubSubChannel

    /// Fetch history for a channel that has not be subscribed to
    func fetchHistory(
        channel: String,
        oldestMessageDate: Date?,
        newestMessageDate: Date?,
        limit: UInt,
        completion: @escaping (Result<PubSubHistoryResult, Error>) -> Void
    )
}
