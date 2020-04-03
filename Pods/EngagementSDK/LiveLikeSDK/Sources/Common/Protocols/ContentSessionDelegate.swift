//
//  ContentSessionDelegate.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-25.
//

import Foundation

/**
 Content Session delegate.
 */
@objc(LLContentSessionDelegate)
public protocol ContentSessionDelegate: AnyObject {
    
    /**
     A real-world reference date used by the EngagementSDK for spoiler-free sync feature.

     - note: This delegate function needs to be implemented to make use of sync.

     - returns: Date of the current video playhead position. Nil is considered to be unsynced.
     */
    @objc optional func playheadTimeSource(_ session: ContentSession) -> Date?

    /**
     Tells the delegate the `ContentSession` status did change

      - Parameters:
        - session: The content session object informing the delegate of this event
        - status: The status of the content session
     */
    @objc optional func session(_ session: ContentSession, didChangeStatus status: SessionStatus)

    /**
     Tells the delegate that the content session encountered an error

     - Parameters:
       - session: The content session object informing the delegate of this event
       - error: The error that the content session encountered
     */
    @objc optional func session(_ session: ContentSession, didReceiveError error: Error)
    
    @objc optional func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage)
}
