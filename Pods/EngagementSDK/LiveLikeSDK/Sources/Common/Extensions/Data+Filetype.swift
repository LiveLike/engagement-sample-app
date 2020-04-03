//
//  Data+Filetype.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-10.
//

// Reference: https://stackoverflow.com/questions/4147311/finding-image-type-from-nsdata-or-uiimage

import Foundation

enum ImageType {
    case png
    case gif
    case jpg
    case tiff
}

extension Data {
    var imageType: ImageType? {
        var values = [UInt8](repeating: 0, count: 1)
        copyBytes(to: &values, count: 1)

        switch values[0] {
        case 0xFF:
            return .jpg
        case 0x89:
            return .png
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        default:
            return nil
        }
    }
}
