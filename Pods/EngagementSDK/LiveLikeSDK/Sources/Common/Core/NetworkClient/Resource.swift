//
//  Resource.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-02.
//

import Foundation

struct Resource<A> {
    var urlRequest: URLRequest
    let parse: (Data) throws -> A
}

extension Resource where A: Decodable {
    init(get url: URL, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        urlRequest = URLRequest(url: url)
        parse = { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = decodingStrategy
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            return try decoder.decode(A.self, from: data)
        }
    }

    init(get url: URL, accessToken: String, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        parse = { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = decodingStrategy
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            return try decoder.decode(A.self, from: data)
        }
    }

    init<Body: Encodable>(url: URL, method: HttpMethod<Body>, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.method
        switch method {
        case .get: ()
        case let .post(body), let .patch(body), let .delete(body):
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try! encoder.encode(body) // swiftlint:disable:this force_try
        }
        parse = { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = decodingStrategy
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            return try decoder.decode(A.self, from: data)
        }
    }

    init<Body: Encodable>(url: URL, method: HttpMethod<Body>, accessToken: String, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        self.init(url: url, method: method, decodingStrategy: decodingStrategy)
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}
