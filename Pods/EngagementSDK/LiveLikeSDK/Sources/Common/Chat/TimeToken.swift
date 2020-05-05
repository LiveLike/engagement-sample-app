//
//  TimeToken.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/2/20.
//

import Foundation

/// Represents a UTC time
///
/// Implements NSCoding for easy conversion to Data using NSKeyedArchiver/NSKeyedUnarchiver.
/// This is helpful if you need to store in persistent storage like UserDefaults.
@objc(LLTimeToken)
public class TimeToken: NSObject, Comparable, NSCoding {

    /// A 17-Digit precision utc time
    var pubnubTimetoken: NSNumber
    /// An approximate Date representation of the TimeToken
    public var approximateDate: Date

    init(pubnubTimetoken: NSNumber) {
        self.pubnubTimetoken = pubnubTimetoken
        self.approximateDate = Date(timeIntervalSince1970: TimeInterval(truncating: pubnubTimetoken) / 10_000_000)
    }

    /// Creates an approximate Timetoken using a Date. Accuracy is not guaranteed.
    public init(date: Date) {
        self.approximateDate = date
        self.pubnubTimetoken = NSNumber(value: date.timeIntervalSince1970 * 10_000_000)
    }

    /// An approximate Timetoken of the 'now' Date. Accuracy is not guranteed.
    public static var now: TimeToken {
        return .init(date: Date())
    }

    public static func < (lhs: TimeToken, rhs: TimeToken) -> Bool {
        return lhs.pubnubTimetoken.compare(rhs.pubnubTimetoken) == .orderedAscending
    }

    public func encode(with coder: NSCoder) {
        coder.encode(pubnubTimetoken, forKey: "pntimetoken")
    }

    public required init?(coder: NSCoder) {
        guard let pnTimeToken = coder.decodeObject(forKey: "pntimetoken") as? NSNumber else {
            return nil
        }
        self.pubnubTimetoken = pnTimeToken
        self.approximateDate = Date(timeIntervalSince1970: TimeInterval(truncating: pubnubTimetoken) / 10_000_000)
    }

}
