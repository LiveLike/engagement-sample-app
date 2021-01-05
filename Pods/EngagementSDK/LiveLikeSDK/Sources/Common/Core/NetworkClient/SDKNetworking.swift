//
//  SDKNetworking.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/22/19.
//

import Foundation
import SystemConfiguration
import UIKit

class SDKNetworking
{
    let urlSession: URLSession

    init(sdkVersion: String) {
        let urlSessionConfig: URLSessionConfiguration = .default
        let userAgent: String = "EngagementSDK/\(sdkVersion) \(UIDevice.modelName)/\(UIDevice.current.systemVersion)"
        urlSessionConfig.httpAdditionalHeaders = ["User-Agent": userAgent]
        urlSession = URLSession(configuration: urlSessionConfig)
    }
}

extension SDKNetworking {
    func load<A>(_ resource: Resource<A>) -> Promise<A> {
        return Promise<A>(work: { fulfilled, rejected in
            assert(Thread.isMainThread == false, "Should not be on main thread")
            self.urlSession.dataTask(with: resource.urlRequest) { data, response, error in
                if let error = error {
                    rejected(error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    rejected(NetworkClientError.invalidResponse(description: "No Response"))
                    return
                }

                guard 200 ..< 300 ~= httpResponse.statusCode else {
                    log.error("bad response: \(httpResponse.statusCode) for request to url: \(String(describing: httpResponse.url))")
                    if let data = data, let message = String(data: data, encoding: .utf8) {
                        log.error(message)
                    }
                    if httpResponse.statusCode == 401 {
                        rejected(NetworkClientError.unauthorized)
                    } else if httpResponse.statusCode == 403 {
                        rejected(NetworkClientError.forbidden)
                    } else if httpResponse.statusCode == 404 {
                        rejected(NetworkClientError.notFound404)
                    } else if 400 ..< 500 ~= httpResponse.statusCode {
                        rejected(NetworkClientError.badRequest)
                    } else if 500 ..< 600 ~= httpResponse.statusCode {
                        rejected(NetworkClientError.internalServerError)
                    } else {
                        rejected(NetworkClientError.invalidResponse(description: "Invalid Status Code: \(httpResponse.statusCode)"))
                    }
                    return
                }

                guard let data = data else {
                    rejected(NetworkClientError.noData)
                    return
                }
                
                // Handle httpMethod `DELETE` which does not return a valid JSON when success
                if let httpMethod = resource.urlRequest.httpMethod,
                    httpMethod == "DELETE" {
                    if let deleteResult = true as? A {
                        fulfilled(deleteResult)
                    } else {
                        // reject when `DELETE` response type is not specified as `Bool` type
                        rejected(NetworkClientError.badDeleteResponseType)
                    }
                    return
                }
                
                do {
                    let result = try resource.parse(data)
                    fulfilled(result)

                } catch {
                    rejected(NetworkClientError.decodingError(error))
                    return
                }
            }.resume()
        })
    }
}

public extension UIDevice {
    /// https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    static var modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }()
}
