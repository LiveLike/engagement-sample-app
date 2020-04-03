//
//  DiscardedReason.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-24.
//

import Foundation

/// Reasons a `WidgetView` won't get displayed
enum DiscardedReason {
    // published during a paused state.
    case paused
    // published too far in the past.
    case invalidPublishDate
    // loading remote images or animations failed.
    case invalidResources
    // no recorded vote for follow up widgets.
    case noVote
}
