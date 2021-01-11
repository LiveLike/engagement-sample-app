//
//  ChatMessageMetadata.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-03-04.
//

import Foundation

struct ChatMessageMetadata: Codable {
    let programDateTime: Date?
    let imageUrl: URL?
}

///  Helpers to encode and decode metadata for a `ChatMessageType`
extension ChatMessageMetadata {
    static func decode(data: String?) -> ChatMessageMetadata? {
        guard let jsonData = data?.data(using: .utf8) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let result = try decoder.decode(ChatMessageMetadata.self, from: jsonData)
            return result
        } catch {
            log.error("Failed to decode \(String(describing: data))")
            return nil
        }
    }

    static func encode(chatMessageMetadata: ChatMessageMetadata) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601Full)
            let jsonData = try encoder.encode(chatMessageMetadata)
            let encodedString = String(data: jsonData, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
            return encodedString
        } catch {
            log.error("Failed to encode \(chatMessageMetadata)")
            return nil
        }
    }
}
