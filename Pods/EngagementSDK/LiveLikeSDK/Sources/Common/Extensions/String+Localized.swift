//
//  String+Localized.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-24.
//

import Foundation

extension String {
    func localized(withComment comment: String = "") -> String {
        let appProvidedString = NSLocalizedString(self, bundle: Bundle.main, comment: comment)
        if appProvidedString != self {
            return appProvidedString
        }
        return NSLocalizedString(self, bundle: Bundle(for: EngagementSDK.self), comment: comment)
    }
}
