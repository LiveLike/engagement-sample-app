//
//  ProgramDetailsVendor.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/23/19.
//

import Foundation

protocol ProgramDetailVendor {
    func getProgramDetails() -> Promise<ProgramDetail>
}

class ProgramDetailClient: ProgramDetailVendor {

    private let programID: String
    private let applicationVendor: LiveLikeRestAPIServicable

    init(programID: String, applicationVendor: LiveLikeRestAPIServicable) {
        self.programID = programID
        self.applicationVendor = applicationVendor
    }

    func getProgramDetails() -> Promise<ProgramDetail> {
        return cachedProgramDetails
    }

    private lazy var cachedProgramDetails: Promise<ProgramDetail> = {
        enum Error: Swift.Error, LocalizedError {
            case invalidURL(String)

            var errorDescription: String? {
                switch self {
                case .invalidURL(let urlString):
                    return "Failed to construct the program url \(urlString). Check that the template and program id are valid."
                }
            }
        }

        return firstly {
            self.applicationVendor.whenApplicationConfig
            }.then { application in
                let programUrlTemplate = application.programDetailUrlTemplate
                let filledTemplate = programUrlTemplate.replacingOccurrences(of: "{program_id}", with: self.programID)
                guard let url = URL(string: filledTemplate) else {
                    let error = Error.invalidURL(filledTemplate)
                    log.error(error.localizedDescription)
                    return Promise(error: error)
                }

                let resource = Resource<ProgramDetail>(get: url)
                return EngagementSDK.networking.load(resource)
        }
    }()
}
