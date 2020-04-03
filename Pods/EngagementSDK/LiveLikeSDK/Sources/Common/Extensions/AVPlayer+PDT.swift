//
//  AVPlayer+PDT.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-09.
//

import AVFoundation

public extension AVPlayer {
    /**
     The Program Date Time (PDT) of the videos current playback position.

     Used by the Engagement SDK to syncronize widgets and chat with the users current video playback position.

     - note: Find more details related to widget syncronization and PDT here: (HTTP Live Streaming - EXT-X-PROGRAM-DATE-TIME)[https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.6]
     */
    @objc var programDateTime: Date {
        guard let currentDate = self.currentItem?.currentDate() else {
            log.warning("Player -> Current stream has no PDT data embedded")
            return Date()
        }
        return currentDate
    }
}
