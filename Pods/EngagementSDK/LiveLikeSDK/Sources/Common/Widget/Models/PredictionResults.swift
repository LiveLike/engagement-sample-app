//
//  PredictionResults.swift
//  EngagementSDK
//
//  Created by Jelzon WORK on 3/18/20.
//

import Foundation

struct PredictionResults: Decodable {
 
    let options: [Option]
    
    struct Option: Decodable {
        let id: String
        let voteCount: Int
    }
}
