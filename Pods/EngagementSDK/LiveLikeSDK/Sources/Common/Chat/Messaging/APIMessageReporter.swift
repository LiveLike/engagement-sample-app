//
//  APIMessageReporter.swift
//  EngagementSDK
//

import Foundation

protocol MessageReporter {
    func report(reportBody: ReportBody, completion: @escaping (Result<Void, Error>) -> Void)
}

struct ReportBody: Encodable {
    let channel: String
    let userId: String
    let nickname: String
    let messageId: String
    let message: String
}

class APIMessageReporter: MessageReporter {
    struct ReportResponse: Decodable { }
    
    private let reportURL: URL
    private let accessToken: AccessToken
    
    init(reportURL: URL, accessToken: AccessToken) {
        self.reportURL = reportURL
        self.accessToken = accessToken
    }
    
    func report(reportBody: ReportBody, completion: @escaping (Result<Void, Error>) -> Void) {
        let resource = Resource<ReportResponse>(
            url: reportURL,
            method: .post(reportBody),
            accessToken: accessToken.asString
        )
        
        firstly {
            EngagementSDK.networking.load(resource).asVoid()
        }.then { _ in
            completion(.success(()))
        }.catch { error in
            completion(.failure(error))
        }
    }
}
