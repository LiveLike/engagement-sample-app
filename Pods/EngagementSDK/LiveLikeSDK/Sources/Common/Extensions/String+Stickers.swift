//
//  String+Stickers.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-17.
//

import Foundation

extension String {
    var stickerIDs: [String] {
        var stickerIDs = [String]()
        do {
            let regex = try NSRegularExpression(pattern: ":(.*?):", options: [])
            let regexRange = NSRange(location: 0, length: utf16.count)

            let matches = regex.matches(in: self, options: [], range: regexRange)

            for match in matches {
                let r = match.range(at: 1)
                if let range = Range(r, in: self) {
                    let shortcode = String(self[range])
                    stickerIDs.append(":\(shortcode):")
                }
            }
        } catch {}

        return stickerIDs
    }
}
