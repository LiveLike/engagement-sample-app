//
//  WidgetVotes.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-05.
//

import Foundation

/// Represents a vote on a prediction widget
public struct PredictionVote: Codable {
    public init(
        id: String,
        widgetID: String,
        optionID: String,
        claimToken: String?
    ) {
        self.id = id
        self.widgetID = widgetID
        self.optionID = optionID
        self.claimToken = claimToken
    }

    @available(*, deprecated, message: "Use init(id:widgetID:optionID:claimToken:) instead.")
    public init(widgetID: String, optionID: String, claimToken: String?) {
        self.id = "n/a"
        self.widgetID = widgetID
        self.optionID = optionID
        self.claimToken = claimToken
    }

    enum CodingKeys: CodingKey {
        case id
        case widgetID
        case optionID
        case claimToken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = "n/a"
        }
        self.widgetID = try container.decode(String.self, forKey: .widgetID)
        self.optionID = try container.decode(String.self, forKey: .optionID)
        self.claimToken = try? container.decode(String.self, forKey: .claimToken)

    }

    /// The id of the Vote
    public let id: String

    /// The id of the prediction widget
    public let widgetID: String

    /// The id of the option that was voted on
    public let optionID: String

    /// A token used to claim rewards on the prediction widget's follow up
    public let claimToken: String?
}

/// Methods to manage how a prediction vote is stored and retrieved
public protocol PredictionVoteRepository: AnyObject {
    /// This is called when the EngagementSDK attempts to claim a prediction follow-up reward
    /// Load the PredictionVote from your database (or other persistent storage)
    /// Then call the completion block
    /// Upon failure to load the PredictionVote you can call `completion(nil)`
    func get(by widgetID: String, completion: @escaping (PredictionVote?) -> Void)
    
    /// This is called when the EngagementSDK attempts to store the user's prediction vote details
    /// Store the PredictionVote in your database (or other persisten storage)
    /// When successfully stored, call `completion(true)`
    /// Upon failure to store the Prediction vote you can call `completion(false)`
    func add(vote: PredictionVote, completion: @escaping (Bool) -> Void)
}

extension WidgetVotes: PredictionVoteRepository {
    func get(by widgetID: String, completion: @escaping (PredictionVote?) -> Void) {
        completion(self.findVote(for: widgetID))
    }

    func add(vote: PredictionVote, completion: @escaping (Bool) -> Void) {
        synchronizingQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            do {
                let url = self.voteJSONFileURL(forWidgetID: vote.widgetID)
                let data = try JSONEncoder().encode(vote)
                try data.write(to: url, options: [.atomic])
                completion(true)
            } catch {
                log.error("Failed to write vote to disk due to error: \(error)")
                completion(false)
            }
        }
    }
}

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
    func addVote(_ vote: PredictionVote, forId widgetID: String) {
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
    func findVote(for widgetID: String) -> PredictionVote? {
        var result: PredictionVote?
        synchronizingQueue.sync { [weak self] in
            guard let self = self else { return }
            result = self.getVote(for: widgetID)
        }
        return result
    }
    
    @discardableResult
    func clearVote(for widgetID: String) -> PredictionVote? {
        var result: PredictionVote?
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
    
    func getVote(for widgetID: String) -> PredictionVote? {
        let url = self.voteJSONFileURL(forWidgetID: widgetID)
        let data = try? Data(contentsOf: url)
        return data.flatMap { try? JSONDecoder().decode(PredictionVote.self, from: $0) }
    }
}
