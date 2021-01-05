//
//  ProgramDetailsVendor.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/23/19.
//

import Foundation

protocol ProgramDetailVendor {
    func getProgramDetails() -> Promise<ProgramDetailResource>
}

class ProgramDetailClient: ProgramDetailVendor {

    private let programID: String
    private let applicationVendor: LiveLikeRestAPIServicable

    init(programID: String, applicationVendor: LiveLikeRestAPIServicable) {
        self.programID = programID
        self.applicationVendor = applicationVendor
    }

    func getProgramDetails() -> Promise<ProgramDetailResource> {
        return cachedProgramDetails
    }

    private lazy var cachedProgramDetails: Promise<ProgramDetailResource> = {
        return firstly {
            self.applicationVendor.whenApplicationConfig
            }.then { application in
                let programUrlTemplate = application.programDetailUrlTemplate
                let filledTemplate = programUrlTemplate.replacingOccurrences(of: "{program_id}", with: self.programID)
                guard let url = URL(string: filledTemplate) else {
                    let error = ProgramDetailsError.invalidURL(filledTemplate)
                    log.error(error.localizedDescription)
                    return Promise(error: error)
                }

                let resource = Resource<ProgramDetailResource>(get: url)
                return EngagementSDK.networking.load(resource)
        }
    }()
}
