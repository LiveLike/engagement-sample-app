//
//  ImageSliderResultsClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import Foundation

protocol ImageSliderResultsClient {
    var delegate: ImageSliderResultsDelegate? { get set }
}

protocol ImageSliderResultsDelegate: AnyObject {
    func resultsClient(didReceiveResults results: ImageSliderResults)
}

protocol ImageSliderVoteClient {
    func vote(url: URL, magnitude: Float) -> Promise<ImageSliderVoteResponse>
}
