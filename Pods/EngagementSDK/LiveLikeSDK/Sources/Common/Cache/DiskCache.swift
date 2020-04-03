//
//  DiskCache.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-15.
//

import Foundation

final class DiskCache: CacheProtocol {
    fileprivate let fileManager = FileManager.default
    fileprivate let writeQueue: DispatchQueue = DispatchQueue(label: "com.livelike.EngagementSDK.write")
    fileprivate let readQueue: DispatchQueue = DispatchQueue(label: "com.livelike.EngagementSDK.read")
    
    private var cachesURL: URL? = try? FileManager.default.url(for: .cachesDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: nil,
                                                               create: false)

    func has(key: String) -> Bool {
        guard let cachesURL = cachesURL else { return false }

        let filePath = cachesURL.appendingPathComponent(key)
        return fileManager.fileExists(atPath: filePath.path)
    }

    func set<T>(object: T, key: String, completion: (() -> Void)?) where T: Cachable {
        writeQueue.async { [weak self] in
            guard
                let self = self,
                let cachesURL = self.cachesURL
                else {
                    completion?()
                    return
            }
            
            if !self.fileManager.fileExists(atPath: cachesURL.path) {
                do {
                    try self.fileManager.createDirectory(atPath: cachesURL.path, withIntermediateDirectories: true, attributes: nil)
                } catch {}
            }

            let filename = key.sanitizedFileName
            let fileURL = cachesURL.appendingPathComponent(filename)

            if let data = object.encode() {
                do {
                    try data.write(to: fileURL)
                } catch {
                    log.error("Failed to cache to disk due to error: \(error)")
                }
            }
            
            completion?()
        }
    }

    func get<T>(key: String, completion: @escaping (T?) -> Void) where T: Cachable {
        readQueue.async { [weak self] in
            guard
                let self = self,
                let cachesURL = self.cachesURL
                else {
                    completion(nil)
                    return
            }

            do {
                let filename = key.sanitizedFileName
                let fileURL = cachesURL.appendingPathComponent(filename)
                let data = try Data(contentsOf: URL(fileURLWithPath: fileURL.path))
                let object = T.decode(data)
                completion(object)
            } catch {
                completion(nil)
            }
        }
    }
    
    func clear() {
        writeQueue.async { [weak self] in
            guard
                let self = self,
                let cachesURL = self.cachesURL
                else {
                    return
            }

            do {
                for file in try self.fileManager.contentsOfDirectory(atPath: cachesURL.path) {
                    try self.fileManager.removeItem(atPath: cachesURL.appendingPathComponent(file).path)
                }
            } catch {
                log.error("DiskCache: Exception removing file: \(error)")
            }
        }
    }
}

// Taken from Stackoverflow: https://stackoverflow.com/a/46864886
fileprivate extension String {
    var sanitizedFileName: String {
        return components(separatedBy: .init(charactersIn: "/:?%*|\"<>")).joined()
    }
}
