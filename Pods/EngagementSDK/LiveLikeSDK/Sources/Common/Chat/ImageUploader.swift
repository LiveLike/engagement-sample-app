//
//  ImageUploader.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 1/13/20.
//

import UIKit

/// Solution inspired by:  https://stackoverflow.com/questions/26335656/how-to-upload-images-to-a-server-in-ios-with-swift
class ImageUploader {

    private let uploadUrl: URL
    private let urlSession: URLSession
    private let accessToken: AccessToken

    init(uploadUrl: URL, urlSession: URLSession, accessToken: AccessToken) {
        self.uploadUrl = uploadUrl
        self.urlSession = urlSession
        self.accessToken = accessToken
    }

    func upload(
        _ image: Data,
        completion: @escaping (Result<ImageResource, Error>) -> Void
    ) {
        self.imageUploadRequest(
            image: image,
            uploadUrl: uploadUrl,
            param: nil,
            completion: completion
        )
    }

    private func imageUploadRequest(
        image: Data,
        uploadUrl: URL,
        param: [String: String]?,
        completion: @escaping (Result<ImageResource, Error>) -> Void
    ) {
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.accessToken.asString)", forHTTPHeaderField: "Authorization")

        let boundary = generateBoundaryString()

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = createBodyWithParameters(
            parameters: param,
            filePathKey: "image",
            imageDataKey: image,
            boundary: boundary
        )

        let task = self.urlSession.dataTask(
            with: request
        ) { (data, _, error) -> Void in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data else {
                return completion(.failure(ImageUploaderError.noDataInResponse))
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let imageResource = try decoder.decode(ImageResource.self, from: data)
                completion(.success(imageResource))
            } catch {
                log.error("\(error)")
                completion(.failure(ImageUploaderError.failedToDecodeDataAsImageResource))
            }
        }
        task.resume()
    }

    private func createBodyWithParameters(
        parameters: [String: String]?,
        filePathKey: String,
        imageDataKey: Data,
        boundary: String
    ) -> Data {
        var body = Data()

        if let parameters = parameters {
            for (key, value) in parameters {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }

        let filename = "user-profile.jpg"
        let mimetype = "image/jpg"

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey)
        body.appendString("\r\n")

        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString.lowercased())"
    }
}

struct ImageResource: Decodable {
    let id: String
    let imageUrl: URL
}

private extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: .utf8, allowLossyConversion: true)
        append(data!)
    }
}
