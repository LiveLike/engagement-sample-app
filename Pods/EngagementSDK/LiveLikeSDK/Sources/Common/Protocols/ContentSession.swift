//
//  ContentSessionProtocol.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dams on 2019-01-18.
//

import AVFoundation
import Foundation

/// Unix epoch. The number of seconds that have elapsed since January 1, 1970 (midnight UTC/GMT), not counting leap seconds
typealias EpochTime = TimeInterval

/// Represents the different  pagination types that can be passed down to `getPostedWidgets`
public enum WidgetPagination {
    case first
    case next
}

/**
 A `ContentSession` instance represents a program item, usually related to a live feed.

 `ContentSession` instance needs to be set in both `ChatViewController` and `WidgetViewController` to receive chat/widgets.

 */
public protocol ContentSession: AnyObject {
    /**
     A unique ID to identify the content currently being played.
     */
    var programID: String { get }
    
    /**
     The status of the `ContentSession`
     */
    var status: SessionStatus { get }

    /// An object that acts as the delegate of the content session.
    var delegate: ContentSessionDelegate? { get set }

    /**
     Pauses both Chat and Widget components.

     Pausing the Engagement SDK stops new widgets and chat message from being displayed. Any widgets currently being displayed, will be dimissed.

     Widgets will still be received by the Engagement SDK, but will only be displayed after `resume()` is called, unless they have timed out.
     */
    func pause()

    /**
     Resumes both Chat and Widget components.
     */
    func resume()

    /**
     Closes the current session.
     */
    func close()
    
    /// Sets an image for the user's chat messages in the current chat room
    func updateUserChatRoomImage(url: URL, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)
    
    /// Retrieves widgets that have already been posted. Each request returns a maximum of 20 posted widgets.
    /// - Parameters:
    ///   - page: Pass the `.next` page parameter to retrieve the next page of the posted widgets.
    ///   - completion: Use the `Result` value to parse an array of posted widgets
    func getPostedWidgets(page: WidgetPagination, completion: @escaping (Result<[Widget]?, Error>) -> Void)
}
