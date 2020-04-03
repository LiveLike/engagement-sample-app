//
//  WidgetVotes.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-05.
//

import Foundation

/// A thread safe class for managing widget votes.
class WidgetVotes {
    private let synchronizingQueue = DispatchQueue(label: "com.livelike.widgetVotesSynchronizer", attributes: .concurrent)
    private let votesFolderURL: URL
    private let expirationPeriod: DateComponents
    
    init(votesFolderURL: URL? = nil, expirationPeriod: DateComponents = DateComponents(day: 1)) {
        self.expirationPeriod = expirationPeriod
        self.votesFolderURL = votesFolderURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LiveLike")
            .appendingPathComponent("WidgetVotes")
        
        if !FileManager.default.fileExists(atPath: self.votesFolderURL.path) {
            try? FileManager.default.createDirectory(at: self.votesFolderURL,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        
        clearExpiredVotes()
    }
}

extension WidgetVotes {
    /// Add a `WidgetVote` for a corresponding widget id
    ///
    /// - Parameters:
    ///   - vote: users `WidgetVote`
    ///   - id: widget id
    func addVote(_ vote: WidgetVote, forId widgetID: String) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let url = self.voteJSONFileURL(forWidgetID: widgetID)
                let data = try JSONEncoder().encode(vote)
                try data.write(to: url, options: [.atomic])
            } catch {
                log.error("Failed to write vote to disk due to error: \(error)")
            }
        }
    }

    /// Check if a `WidgetVote` exists for a specific widget id
    ///
    /// - Parameter widgetId: widget id
    /// - Returns: `WidgetVote` if one exists
    func findVote(for widgetID: String) -> WidgetVote? {
        var result: WidgetVote?
        synchronizingQueue.sync { [weak self] in
            guard let self = self else { return }
            result = self.getVote(for: widgetID)
        }
        return result
    }
    
    @discardableResult
    func clearVote(for widgetID: String) -> WidgetVote? {
        var result: WidgetVote?
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            result = self.getVote(for: widgetID)
            try? FileManager.default.removeItem(at: self.voteJSONFileURL(forWidgetID: widgetID))
        }
        return result
    }

    /// Clear all votes
    func clearAllVotes() {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            guard
                let self = self,
                let jsonURLs = try? FileManager.default
                    .contentsOfDirectory(at: self.votesFolderURL,
                                         includingPropertiesForKeys: nil,
                                         options: [])
            else {
                return
            }
            
            for voteJSONFileURL in jsonURLs {
                try? FileManager.default.removeItem(at: voteJSONFileURL)
            }
        }
    }
    
    func clearExpiredVotes() {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            guard
                let self = self,
                let jsonURLs = try? FileManager.default
                    .contentsOfDirectory(at: self.votesFolderURL,
                                         includingPropertiesForKeys: [.creationDateKey],
                                         options: [])
            else {
                return
            }
            
            for voteJSONFileURL in jsonURLs {
                guard
                    let values = try? voteJSONFileURL.resourceValues(forKeys: [.creationDateKey]),
                    let creationDate = values.creationDate
                else {
                    continue
                }
                
                if
                    let expirationDate = Calendar.current.date(byAdding: self.expirationPeriod, to: creationDate),
                    expirationDate <= Date()
                {
                    try? FileManager.default.removeItem(at: voteJSONFileURL)
                }
            }
        }
    }
}

private extension WidgetVotes {
    func voteJSONFileURL(forWidgetID widgetID: String) -> URL {
        return votesFolderURL
            .appendingPathComponent("WidgetID \(widgetID)")
            .appendingPathExtension("json")
    }
    
    func getVote(for widgetID: String) -> WidgetVote? {
        let url = self.voteJSONFileURL(forWidgetID: widgetID)
        let data = try? Data(contentsOf: url)
        return data.flatMap { try? JSONDecoder().decode(WidgetVote.self, from: $0) }
    }
}
