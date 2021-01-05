//
//  MediaRepository.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/26/20.
//

import UIKit

class MediaRepository {
    
    private let mediaCache: Cache
    
    init(cache: Cache) {
        self.mediaCache = cache
    }

    func getImagePromise(url: URL) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            self.getImage(url: url) { result in
                switch result {
                case .success(let success):
                    fulfill(success.image)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    struct GetImageResult {
        let imageData: Data
        let image: UIImage
        let imageType: ImageType?
    }
    
    /// Gets the image from cache or downloads if cache miss.
    /// Completion executes on main thread.
    func getImage(url: URL, completion: @escaping (Result<GetImageResult, Error>) -> Void) {
        if mediaCache.has(key: url.absoluteString) {
            mediaCache.get(key: url.absoluteString) { (data: Data?) in
                DispatchQueue.main.async {
                    guard let data = data else {
                        completion(.failure(NilError()))
                        return
                    }
                    guard let image = UIImage(data: data) else {
                        completion(.failure(MediaRepositoryError.mediaNotUIImage))
                        return
                    }
                    let success = GetImageResult(
                        imageData: data,
                        image: image,
                        imageType: data.imageType
                    )
                    completion(.success(success))
                }
            }
        } else {
            downloadMedia(url: url) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        guard let image = UIImage(data: data) else {
                            completion(.failure(MediaRepositoryError.mediaNotUIImage))
                            return
                        }
                        let success = GetImageResult(
                            imageData: data,
                            image: image,
                            imageType: data.imageType
                        )
                        completion(.success(success))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /// Fails if any image fails to download
    /// Result maintains order of 'urls'
    func getImages(urls: [URL], completion: @escaping (Result<[GetImageResult], Error>) -> Void) {
        var results: [GetImageResult?] = [GetImageResult?](repeating: nil, count: urls.count)
        var getImageCompleteCount = 0

        urls.enumerated().forEach { index, url in
            self.getImage(url: url ) {
                switch $0 {
                case .success(let result):
                    results[index] = result
                case .failure(let error):
                    completion(.failure(error))
                }
                getImageCompleteCount += 1

                /// Success result if finished all downloads
                if getImageCompleteCount == urls.count {
                    completion(.success(results.compactMap { $0 }))
                }
            }
        }
    }
    
    /// Downloads media at url and sets in cache
    private func downloadMedia(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        EngagementSDK.networking.urlSession.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(MediaRepositoryError.downloadFailedWithNoError))
                }
                return
            }
            // Set in cache then complete
            self.mediaCache.set(object: data, key: url.absoluteString) {
                completion(.success(data))
            }
        }.resume()
    }
    
    /// Downloads media from server if cache miss
    func prefetchMedia(url: URL, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        guard !mediaCache.has(key: url.absoluteString) else {
            log.info("Prefetch not needed because media already found in cache.")
            completion?(.success(true))
            return
        }
        downloadMedia(url: url) { result in
            switch result {
            case .success:
                log.info("Prefetch completed for media at \(url)")
                completion?(.success(true))
            case .failure(let error):
                log.error("Prefetch failed with error: \(String(describing: error))")
                completion?(.failure(error))
            }
        }
    }
    
    func prefetchMediaPromise(url: URL) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.prefetchMedia(url: url) { result in
                switch result {
                case .success:
                    fulfill(())
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    /// Downloads media from server if cache miss
    /// Completes when all media has been prefetched
    func prefetchMedia(urls: [URL], completion: ((Result<Bool, Error>) -> Void)? = nil) {
        var prefectCount = urls.count
        urls.forEach {
            prefetchMedia(url: $0) { result in
                prefectCount -= 1
                if prefectCount == 0 {
                    completion?(.success(true))
                }
            }
        }
    }
}
