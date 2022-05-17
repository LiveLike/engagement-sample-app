//
//  EtherscanAPI.swift
//  Sample App
//
//  Created by Mike Moloksher on 5/13/22.
//  Copyright © 2022 LiveLike. All rights reserved.
//

import Foundation

struct EtherscanResponse: Decodable {
    let status: String
    let message: String
    let result: String
}

enum EtherscanError: Error {
    case jsonParsingError(Error)
}

class EtherscanAPI {
    
    private let apiKey: String
    private var baseUrl: URLComponents
    private let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: nil)
    
    enum ETHNetwork {
        case production
        case ropsten
    }

    init(
        ethNetwork: ETHNetwork,
        apiKey: String
    ) {
        self.apiKey = apiKey
        
        switch ethNetwork {
        case .production:
            baseUrl = URLComponents(string: "https://api.etherscan.io/api")!
        case .ropsten:
            baseUrl = URLComponents(string: "https://api-ropsten.etherscan.io/api")!
        }
    }
    
    func getERC20TokenBalance(
        walletAddress: String,
        contractAddress: String,
        completion: @escaping (Result<EtherscanResponse, Error>) -> Void)
    {
        baseUrl.queryItems = [
            URLQueryItem(name: "module", value: "account"),
            URLQueryItem(name: "action", value: "tokenbalance"),
            URLQueryItem(name: "contractaddress", value: contractAddress),
            URLQueryItem(name: "address", value: walletAddress),
            URLQueryItem(name: "tag", value: "latest"),
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        
        let session = URLSession.shared
        let request = URLRequest(url: baseUrl.url!)
                
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
            guard error == nil else {
                return
            }
                
            guard let data = data else {
                return
            }
                
            do {
                //create decodable object from data
                let decodedObject = try JSONDecoder().decode(EtherscanResponse.self, from: data)
                completion(.success(decodedObject))
            } catch let error {
                completion(Result.failure(EtherscanError.jsonParsingError(error as! DecodingError)))
            }
        })

        task.resume()
    }
    
}
