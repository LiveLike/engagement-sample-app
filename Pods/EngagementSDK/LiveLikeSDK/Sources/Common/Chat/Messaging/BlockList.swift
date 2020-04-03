//
//  BlockList.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/27/19.
//

import Foundation

struct BlockList {
    private var blockedUserIDs: Set<ChatUser.ID>
    private var listOwnerUserID: ChatUser.ID

    init(for userID: ChatUser.ID) {
        listOwnerUserID = userID
        blockedUserIDs = BlockList.loadBlockedUserIDs(for: userID)
    }
}

internal extension BlockList {
    func contains(user: ChatUser) -> Bool {
        return blockedUserIDs.contains(user.id)
    }

    mutating func block(userWithID id: ChatUser.ID) {
        guard listOwnerUserID != id else { return }
        blockedUserIDs.insert(id)
        try? save()
    }

    mutating func unblock(userWithID id: ChatUser.ID) {
        guard listOwnerUserID != id else { return }
        blockedUserIDs.remove(id)
        try? save()
    }
}

private extension BlockList {
    static let liveLikeUserDataFolderName = "LiveLikeUserData"
    static let blockListsFolderName = "BlockLists"

    static var decorder: PropertyListDecoder { return PropertyListDecoder() }
    static var encoder: PropertyListEncoder { return PropertyListEncoder() }

    static func fileURL(for userID: ChatUser.ID) -> URL {
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(liveLikeUserDataFolderName)
            .appendingPathComponent(blockListsFolderName)
            .appendingPathComponent(userID.asString)
    }

    static func loadBlockedUserIDs(for userID: ChatUser.ID) -> Set<ChatUser.ID> {
        do {
            let data = try Data(contentsOf: fileURL(for: userID))
            return try decorder.decode(Set<ChatUser.ID>.self, from: data)
        } catch {
            return .init()
        }
    }

    func save() throws {
        let data = try BlockList.encoder.encode(blockedUserIDs)
        let fileURL = BlockList.fileURL(for: listOwnerUserID)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }

        try data.write(to: fileURL)
    }
}
