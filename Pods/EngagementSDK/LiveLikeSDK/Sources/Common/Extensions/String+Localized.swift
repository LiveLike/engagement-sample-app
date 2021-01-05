//
//  String+Localized.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-24.
//

import Foundation

extension String {
    func localized(withParam param: String? = nil, comment: String = "") -> String {
        let appProvidedString = NSLocalizedString(self, bundle: Bundle.main, comment: comment)
        if appProvidedString != self {
            if let param = param {
                return String(format: appProvidedString, param)
            }
            return appProvidedString
        }
        
        let sdkProvidedString =  NSLocalizedString(self, bundle: Bundle(for: EngagementSDK.self), comment: comment)
        if let param = param {
            return String(format: sdkProvidedString, param)
        }
        return sdkProvidedString
    }
}
