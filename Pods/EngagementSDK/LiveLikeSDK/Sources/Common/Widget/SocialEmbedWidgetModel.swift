//
//  SocialEmbedWidgetModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 2/1/21.
//

import Foundation

/// An object that reflects the state of a Social Embed widget on the server
public class SocialEmbedWidgetModel: SocialEmbedWidgetModelable {

    // MARK: Data
    
    /// Objects that hold oembed content
    public let items: [Item]
    /// Comment / Caption of the widget
    public let comment: String?
    
    // MARK: Metadata

    public let id: String
    public let interactionTimeInterval: TimeInterval
    public let kind: WidgetKind
    public let createdAt: Date
    public let publishedAt: Date?
    public let customData: String?
    
    // MARK: Private Properties
    
    private let data: SocialEmbedWidgetResource
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let userProfile: UserProfile
    private let eventRecorder: EventRecorder
    private let programID: String
    
    init(
        resource: SocialEmbedWidgetResource,
        eventRecorder: EventRecorder,
        livelikeAPI: LiveLikeRestAPIServicable,
        userProfile: UserProfile
    ) {
        self.id = resource.id
        self.comment = resource.comment
        self.kind = resource.kind
        self.createdAt = resource.createdAt
        self.publishedAt = resource.publishedAt
        self.customData = resource.customData
        self.interactionTimeInterval = resource.timeout.timeInterval
        self.data = resource
        self.livelikeAPI = livelikeAPI
        self.userProfile = userProfile
        self.eventRecorder = eventRecorder
        self.programID = resource.programId
        
        // Create embed items
        self.items = resource.items.map({
            SocialEmbedWidgetModel.Item(
                id: $0.id,
                url: $0.url,
                oembed: OEmbed(
                    html: $0.oembed.html,
                    providerName: $0.oembed.providerName
                )
            )
        })
    }
    
    public struct Item {
        public let id: String
        public let url: URL
        public let oembed: OEmbed
    }
    
    public struct OEmbed {
        public let html: String
        public let providerName: String
    }
    
    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        self.eventRecorder.record(
            .widgetDisplayed(programID: programID, kind: kind.analyticsName, widgetId: id, widgetLink: nil)
        )
        guard let impressionURL = data.impressionUrl else { return }
        firstly {
            livelikeAPI.createImpression(
                impressionURL: impressionURL,
                userSessionID: userProfile.userID.asString,
                accessToken: userProfile.accessToken
            )
        }.then { _ in
            completion(.success(()))
        }.catch { error in
            completion(.failure(error))
        }

    }
}
