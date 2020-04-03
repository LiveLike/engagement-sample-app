//
//  Logger.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/8/19.
//

import Foundation
import os

let log = Logger.self

class Logger {
    // Private
    private static let logFilename = "livelike.log"
    private static let fileManager = FileManager.default

    static var LoggingLevel: LogLevel = .none
    static var LogToFile = true

    // Internal
    static func initialize() {
        removeLogFile()
        createLogFile()
    }

    static func dev(_ message: String, function: String = #function, line: Int = #line) {
        #if DEBUG
            print("DEV - \(function):\(line) | \(message)")
        #endif
    }
    
    static func verbose(_ message: String) {
        custom(level: .verbose, message: message)
    }

    static func debug(_ message: String) {
        custom(level: .debug, message: message)
    }

    static func info(_ message: String) {
        custom(level: .info, message: message)
    }

    static func warning(_ message: String) {
        custom(level: .warning, message: message)
    }

    static func error(_ message: String) {
        custom(level: .error, message: message)
    }

    static func error(_ error: Error) {
        custom(level: .error, message: error.localizedDescription)
    }

    static func severe(_ message: String) {
        custom(level: .severe, message: message)
    }

    private class func custom(level: LogLevel, message: String) {
        if LoggingLevel.rawValue <= level.rawValue {
            let log = "[EngagementSDK] [\(level.name)] \(message)"
            if LogToFile {
                Logger.writeMessageToFile(message: log)
            }
            os_log("%{public}@", log)
        }
    }

    static func writeMessageToFile(message: String) {
        guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docsDir.appendingPathComponent(logFilename)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let fileHandler = FileHandle(forUpdatingAtPath: fileURL.path)
                if let messageData = "\n\(message)".data(using: .utf8) {
                    fileHandler?.seekToEndOfFile()
                    fileHandler?.write(messageData)
                    fileHandler?.closeFile()
                }
            } else {
                try message.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Could not write to file: \(error)")
        }
    }

    static func removeLogFile() {
        guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docsDir.appendingPathComponent(logFilename)
        do {
            try fileManager.removeItem(atPath: fileURL.path)
        } catch {
            print("Could not remove file: \(error)")
        }
    }

    static func createLogFile() {
        guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docsDir.appendingPathComponent(logFilename)
        fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
}
