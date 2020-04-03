//
//  ChatViewHandlerConfig.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-08.
//

import Foundation
import UIKit

/**
 A `ChatViewHandlerConfig` instance represents a chat cell at the given index.
 */
struct ChatViewHandlerConfig {
    /// An object giving more information related to the chat message.
    var messageViewModel: MessageViewModel

    /// An index path locating a row in tableView.
    var indexPath: IndexPath

    /// An instance of `Theme`.
    var theme: Theme?
    
    var timestampFormatter: TimestampFormatter?
    
    var shouldDisplayDebugVideoTime: Bool = false

    init(messageViewModel: MessageViewModel,
         indexPath: IndexPath,
         theme: Theme? = nil,
         timestampFormatter: TimestampFormatter?,
         shouldDisplayDebugVideoTime: Bool) {
        
        self.messageViewModel = messageViewModel
        self.indexPath = indexPath
        self.theme = theme
        self.shouldDisplayDebugVideoTime = shouldDisplayDebugVideoTime
        
        if shouldDisplayDebugVideoTime {
            self.timestampFormatter = { date in
                let dateFormatter = DateFormatter()
                dateFormatter.amSymbol = "am"
                dateFormatter.pmSymbol = "pm"
                dateFormatter.setLocalizedDateFormatFromTemplate("MMM d hh:mm:ss:SSSS")
                return dateFormatter.string(from: date)
            }
        } else {
            self.timestampFormatter = timestampFormatter
        }
    }
}
