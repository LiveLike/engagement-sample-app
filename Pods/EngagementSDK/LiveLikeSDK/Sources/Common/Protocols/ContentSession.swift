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

/**
 A `ContentSession` instance represents a program item, usually related to a live feed.

 `ContentSession` instance needs to be set in both `ChatViewController` and `WidgetViewController` to receive chat/widgets.

 */
@objc(LLContentSession)
public protocol ContentSession {
    /**
     A unique ID to identify the content currently being played.
     */
    var programID: String { get }

    /// A unique ID to identify the chat room that is currently entered
    var currentChatRoomID: String? { get }

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

    func install(plugin: Plugin)

    /// Joins and displays the room on a ChatViewController
    func enterChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Leave a room to stop receiving updates
    func leaveChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Join the room to begin receiving updates
    func joinChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Returns a list of chat messages with and since a given timestamp
    func getLatestChatMessages(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping ([ChatMessage]) -> Void,
        failure: @escaping (Error) -> Void
    )
    
    /// Provides the count of chat messages
    /// - Parameters:
    ///   - roomID: The id of the room
    ///   - timestamp: The timestamp to start counting from
    ///   - completion: Completion block that returns the count of chat messages
    ///   - failure: Failure block
    func getChatMessageCount(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping (Int) -> Void,
        failure: @escaping (Error) -> Void
    )

    /// Sets an image for the user's chat messages in the current chat room
    func updateUserChatRoomImage(url: URL, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

}
