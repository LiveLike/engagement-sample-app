//
//  WidgetPayloadParser.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/8/20.
//

import Foundation

struct WidgetPayloadParser {
    
    private init() { }
    
    static func parse(_ jsonObject: Any) throws -> WidgetResource {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return try decoder.decode(WidgetResource.self, from: jsonData)
    }
}
