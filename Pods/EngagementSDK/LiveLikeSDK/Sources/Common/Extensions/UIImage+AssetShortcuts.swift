//
//  UIImage+AssetShortcuts.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 6/24/19.
//

import UIKit

internal extension UIImage {
    static func from(asset: Asset,
                     compatibleWith traitCollection: UITraitCollection? = nil)
        -> UIImage
    {
        guard
            let image = UIImage(named: asset.filename,
                                in: asset.bundle,
                                compatibleWith: traitCollection)
        else {
            let traitCollectionComponent = (traitCollection == nil
                ? ""
                : "\nfor traitCollection: \(traitCollection!)")
            fatalError(
                """
                Could not load UIImage for asset with:
                filename: \(asset.filename)
                and extension: \(asset.extension)
                in bundle: \(asset.bundle) \(traitCollectionComponent)
                """)
        }

        return image
    }
}

internal protocol File {
    var filename: String { get }
    var `extension`: String { get }
}

internal protocol BundleResource: File {
    var bundle: Bundle { get }
}

internal protocol AssetProtocol: BundleResource {}

internal enum SupportedImageFiletypes: String {
    case png
    var `extension`: String { return rawValue }
}

internal protocol Image: AssetProtocol {
    var filetype: SupportedImageFiletypes { get }
}

extension Image {
    var `extension`: String { return filetype.extension }
}

internal struct Asset: AssetProtocol {
    let filename: String
    let `extension`: String
    let bundle: Bundle

    init(filename: String,
         extension: String,
         bundle: Bundle = Bundle(for: EngagementSDK.self))
    {
        self.filename = filename
        self.extension = `extension`
        self.bundle = bundle
    }
}

extension Asset {
    static let imageExtension = "png"

    static var flag: Asset {
        return .init(filename: "chat_flag", extension: imageExtension)
    }
}

private extension UIImage {
    
    func saveImage(name: String) -> URL? {
        guard let imageData = self.jpegData(compressionQuality: 1) else {
            return nil
        }
        do {
            let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }

    // returns an image if there is one with the given name, otherwise returns nil
    func loadImage(withName name: String) -> UIImage? {
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
        return UIImage(contentsOfFile: imageURL.path)
    }
    
}
