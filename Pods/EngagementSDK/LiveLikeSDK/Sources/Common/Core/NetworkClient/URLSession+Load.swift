//
//  URLSession+Load.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-02.
//

import Foundation

enum NetworkClientError: Error {
    case invalidResponse(description: String)
    case internalServerError
    case badRequest
    case noData
    case decodingError(Error)
    case forbidden
    case unauthorized
    case badDeleteResponseType
}
