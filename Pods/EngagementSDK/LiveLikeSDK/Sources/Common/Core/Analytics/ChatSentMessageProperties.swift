//
//  ChatSentMessageProperties.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-29.
//

import Foundation

struct ChatSentMessageProperties {
    let characterCount: Int
    let messageId: String
    let stickerIDs: [String]
    let stickerCount: Int
    let stickerIndices: [[Int: Int]]
    let hasExternalImage: Bool
}

extension ChatSentMessageProperties {
    static func calculateStickerIndices(stickerIDs: [String], stickers: [StickerPack]) -> [[Int: Int]] {
        var indices = [[Int: Int]]()

        for id in stickerIDs {
            for (index, stickerPack) in stickers.enumerated() {
                if let resultIndex = stickerPack.stickers.firstIndex(where: { $0.shortcode == id.replacingOccurrences(of: ":", with: "") }) {
                    indices.append([index + 1: resultIndex + 1]) // Reporting indexes need to start at 1, not 0.
                }
            }
        }

        return indices
    }
}
