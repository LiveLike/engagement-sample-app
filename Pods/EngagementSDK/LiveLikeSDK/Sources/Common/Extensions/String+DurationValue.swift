/* Copyright (c) 2016 Igor Palaguta <igor.palaguta@gmail.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 import UIKit
 */

import Foundation

typealias Seconds = TimeInterval
extension String {
    /// Converts a ISO8601 duration fromat string to a TimeInterval
    ///
    /// For example the following `String` value returns 607 seconds
    /// ````
    ///  P0DT00H10M07S
    /// ````
    ///
    /// - Returns: TimeInterval is seconds
    func timeIntervalFromISO8601Duration() -> Seconds? {
        guard let unitValues = self.durationUnitValues else {
            return nil
        }

        var components = DateComponents()
        for (unit, value) in unitValues {
            components.setValue(value, for: unit)
        }

        var interval: Int = 0
        if let second = components.second {
            interval += second
        }
        if let minute = components.minute {
            interval += (minute * 60)
        }
        if let hour = components.hour {
            interval += (hour * 60 * 60)
        }
        if let day = components.day {
            interval += (day * 24 * 60 * 60)
        }
        return Double(interval)
    }
}

private let dateUnitMapping: [Character: Calendar.Component] = ["Y": .year, "M": .month, "W": .weekOfYear, "D": .day]
private let timeUnitMapping: [Character: Calendar.Component] = ["H": .hour, "M": .minute, "S": .second]

private extension String {
    var durationUnitValues: [(Calendar.Component, Int)]? {
        guard hasPrefix("P") else {
            return nil
        }

        let duration = String(dropFirst())

        guard let separatorRange = duration.range(of: "T") else {
            return duration.unitValuesWithMapping(dateUnitMapping)
        }

        let date = String(duration[..<separatorRange.lowerBound])
        let time = String(duration[separatorRange.upperBound...])
        guard let dateUnits = date.unitValuesWithMapping(dateUnitMapping),
            let timeUnits = time.unitValuesWithMapping(timeUnitMapping) else {
            return nil
        }

        return dateUnits + timeUnits
    }

    func unitValuesWithMapping(_ mapping: [Character: Calendar.Component]) -> [(Calendar.Component, Int)]? {
        if isEmpty {
            return []
        }

        var components: [(Calendar.Component, Int)] = []
        let identifiersSet = CharacterSet(charactersIn: String(mapping.keys))
        let scanner = Scanner(string: self)
        while !scanner.isAtEnd {
            var value: Int = 0
            if !scanner.scanInt(&value) {
                return nil
            }
            var identifier: NSString?
            if !scanner.scanCharacters(from: identifiersSet, into: &identifier) || identifier?.length != 1 {
                return nil
            }
            let unit = mapping[Character(identifier! as String)]!
            components.append((unit, value))
        }
        return components
    }
}
