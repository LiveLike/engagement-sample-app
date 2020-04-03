//
//  InternalErrorReporter.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/1/19.
//

import Foundation

/// An object used to pass errors back up to the EngagementSDK
class InternalErrorReporter {
    weak var delegate: InternalErrorDelegate?

    func report(setupError: EngagementSDK.SetupError) {
        delegate?.setupError(setupError)
    }
}

protocol InternalErrorDelegate: AnyObject {
    func setupError(_ error: EngagementSDK.SetupError)
}
