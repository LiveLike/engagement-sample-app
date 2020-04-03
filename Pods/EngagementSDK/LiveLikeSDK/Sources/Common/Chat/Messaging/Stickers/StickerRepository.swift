//
//  StickerManager.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-21.
//

import Foundation

class StickerRepository {
    private var stickerPacks = [StickerPack]()
    private var stickers = [String: Sticker]()

    private let stickerPacksURL: URL

    init(apiBaseURL: URL) {
        stickerPacksURL = apiBaseURL.appendingPathComponent("sticker-packs")
    }

    func getStickerPacks() -> [StickerPack] {
        return stickerPacks
    }

    func getAll() -> [Sticker] {
        return stickers.map { $1 }
    }

    func get(id: String) -> Sticker? {
        return stickers[id]
    }

    func create(item: Sticker) {
        stickers[item.shortcode] = item
    }

    func update(item: Sticker) {
        stickers[item.shortcode] = item
    }

    func delete(item: Sticker) {
        stickers.removeValue(forKey: item.shortcode)
    }
}

extension StickerRepository {
    @discardableResult
    func retrieve(programID: String) -> Promise<StickerPackResponse> {
        guard let stickerPackPromise = getStickerPack(programID: programID) else {
            log.warning("Unable to retrieve sticker pack for programID: \(programID)")
            return Promise<StickerPackResponse>(error: StickerRepositoryError.invalidURL)
        }

        stickerPackPromise.then { [weak self] stickerPackResponse in
            self?.setupStickerSet(stickerPacks: stickerPackResponse.results)
        }.catch { error in
            log.error("StickerManager.retrieveStickerPacks: \(error.localizedDescription)")
        }

        return stickerPackPromise
    }

    private func setupStickerSet(stickerPacks: [StickerPack]) {
        self.stickerPacks = stickerPacks
        for stickerPack in stickerPacks {
            for sticker in stickerPack.stickers {
                stickers[sticker.shortcode] = sticker
            }
        }
        cacheStickerPackIcons()
        cacheStickerSet()
    }

    private func cacheStickerPackIcons() {
        let imageURLs = stickerPacks.map { $0.file }
        Cache.shared.downloadAndCacheImages(urls: imageURLs, completion: nil)
    }

    private func cacheStickerSet() {
        let imageURLs = stickers.map { $1.file }
        Cache.shared.downloadAndCacheImages(urls: imageURLs, completion: nil)
    }
}

extension StickerRepository: StickerPackRetriever {
    func getStickerPack(programID: String) -> Promise<StickerPackResponse>? {
        var components = URLComponents(url: stickerPacksURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "program_id", value: programID)
        ]

        guard let url = components?.url else {
            return nil
        }

        let resource = Resource<StickerPackResponse>(get: url)
        return EngagementSDK.networking.load(resource)
    }
}

enum StickerRepositoryError: Error {
    case invalidURL
}
