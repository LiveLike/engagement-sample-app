//
//  StickerManager.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-21.
//

import Foundation

class StickerRepository {
    private var cachedStickerPacks: [StickerPack]?
    private var cachedStickersByID: [String: Sticker]?

    private let stickerPacksURL: URL
    private let mediaRepository: MediaRepository = EngagementSDK.mediaRepository

    init(stickerPacksURL: URL) {
        self.stickerPacksURL = stickerPacksURL
    }
    
    private var whenStickerPackResource: Promise<StickerPackResponse>?

    func getStickerPacks(completion: @escaping (Result<[StickerPack], Error>) -> Void) {
        if let cachedStickerPacks = self.cachedStickerPacks {
            completion(.success(cachedStickerPacks))
            return
        }
        
        let resource = Resource<StickerPackResponse>(get: stickerPacksURL)
        let request = whenStickerPackResource ?? EngagementSDK.networking.load(resource)
        
        // Debounce consecutive calls
        if whenStickerPackResource == nil {
            self.whenStickerPackResource = request
        }
        
        firstly {
            request
        }.then { stickerPackResource in
            self.cachedStickerPacks = stickerPackResource.results
            var cachedStickersByID: [String: Sticker] = [:]
            for stickerPack in stickerPackResource.results {
                for sticker in stickerPack.stickers {
                    cachedStickersByID[sticker.shortcode] = sticker
                }
            }
            self.cachedStickersByID = cachedStickersByID
            completion(.success(stickerPackResource.results))
        }.catch { error in
            completion(.failure(error))
        }
    }
    
    func getSticker(id: String, completion: @escaping (Result<Sticker, Error>) -> Void) {
        self.getStickerPacks { result in
            switch result {
            case .success(let stickerPacks):
                if let sticker = stickerPacks.flatMap({ $0.stickers }).first(where: { $0.shortcode == id }) {
                    completion(.success(sticker))
                } else {
                    completion(.failure(NilError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private var prefetchStickersPromise: Promise<StickerPackResponse>?
    
    private func prefetchStickers(stickerPackResource: StickerPackResponse) -> Promise<StickerPackResponse> {
        if let prefetchStickersPromise = prefetchStickersPromise {
            return prefetchStickersPromise
        }
        
        let allStickerPackIconURLs = stickerPackResource.results.compactMap { $0.file }
        let allStickerURLs = stickerPackResource.results.flatMap{ $0.stickers }.map { $0.file }
        let allPrefecthPromises = (allStickerPackIconURLs + allStickerURLs).map { mediaRepository.prefetchMediaPromise(url: $0)}
        let prefetchPromise = firstly {
            Promises.all(allPrefecthPromises)
        }.then { _ in
            return Promise(value: stickerPackResource)
        }
        self.prefetchStickersPromise = prefetchPromise
        return prefetchPromise
    }
}

enum StickerRepositoryError: Error {
    case invalidURL
}
