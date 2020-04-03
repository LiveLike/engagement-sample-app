//
//  String+Emoji.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/22/19.
//

import Foundation

// https://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
extension UnicodeScalar {
    var isEmoji: Bool {
        switch value {
        case 0x1F600 ... 0x1F64F, // Emoticons
             0x1F300 ... 0x1F5FF, // Misc Symbols and Pictographs
             0x1F680 ... 0x1F6FF, // Transport and Map
             0x1F1E6 ... 0x1F1FF, // Regional country flags
             0x2600 ... 0x26FF, // Misc symbols
             0x2700 ... 0x27BF, // Dingbats
             0xE0020 ... 0xE007F, // Tags
             0xFE00 ... 0xFE0F, // Variation Selectors
             0x1F900 ... 0x1F9FF, // Supplemental Symbols and Pictographs
             0x1F018 ... 0x1F270, // Various asian characters
             0x238C ... 0x2454, // Misc items
             0x20D0 ... 0x20FF: // Combining Diacritical Marks for Symbols
            return true

        default: return false
        }
    }
}

extension String {
    var containsEmoji: Bool {
        return unicodeScalars.contains { $0.isEmoji }
    }
}
