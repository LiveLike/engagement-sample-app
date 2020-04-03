//
//  Optionsl+unwrap.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-21.
//

import Foundation

struct NilError: Error {}

extension Optional {
    func unwrap() throws -> Wrapped {
        guard let result = self else {
            throw NilError()
        }
        return result
    }
}
