//
//  HTTPMethod.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-02.
//

import Foundation

enum HttpMethod<Body> {
    case get
    case post(Body)
    case patch(Body)
    case delete(Body)

    var method: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        }
    }
}
