//
//  MockImageSliderResultsClient.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import Foundation

class MockImageSliderResultsClient: ImageSliderResultsClient, ImageSliderVoteClient {
    func vote(url: URL, magnitude: Float) -> Promise<ImageSliderVoteResponse> {
        return Promise()
    }

    weak var delegate: ImageSliderResultsDelegate? {
        didSet {
            let randomMagnitude: Float = .random(in: 0 ... 1)
            delegate?.resultsClient(didReceiveResults: ImageSliderResults(averageMagnitude: randomMagnitude.description))
        }
    }
}
