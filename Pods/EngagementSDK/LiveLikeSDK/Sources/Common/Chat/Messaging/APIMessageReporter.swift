//
//  APIMessageReporter.swift
//  EngagementSDK
//

import Foundation

class APIMessageReporter: MessageReporter {
    private let reportURL: URL
    private let accessToken: AccessToken
    
    init(reportURL: URL, accessToken: AccessToken) {
        self.reportURL = reportURL
        self.accessToken = accessToken
    }
    
    func report(messageViewModel: MessageViewModel) -> Promise<Void> {
        //swiftlint:disable nesting
        struct ReportBody: Encodable {
            let channel: String
            let userId: String
            let nickname: String
            let messageId: String
            let message: String
        }
        
        struct ReportResponse: Decodable {
        }
        //swiftlint:enable nesting
        
        let body = ReportBody(channel: messageViewModel.channel,
                              userId: messageViewModel.sender?.id.asString ?? "*** ERROR: Unknown Sender ***",
                              nickname: messageViewModel.sender?.nickName ?? "*** ERROR: Unknown Sender ***",
                              messageId: messageViewModel.id.asString,
                              message: messageViewModel.message)
        
        let resource = Resource<ReportResponse>(url: reportURL,
                                                method: .post(body),
                                                accessToken: accessToken.asString)
        
        return EngagementSDK.networking.load(resource).asVoid()
    }
}
