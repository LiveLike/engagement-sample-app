//
//  AlertWidgetViewModel.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/2/20.
//

import Foundation
import UIKit

/// A model containing the data of an Alert Widget
public class AlertWidgetModel: AlertWidgetModelable {
    
    // MARK: Data

    /// The title of the Alert Widget
    public var title: String?
    /// The URL of the link of the Alert Widget
    public var linkURL: URL?
    /// The label describing the `linkURL`
    public var linkLabel: String?
    /// The text contents of the Alert Widget
    public var text: String?
    /// The URL of the image of the Alert Widget
    public var imageURL: URL?

    // MARK: Metadata

    /// The id of the Alert Widget
    public var id: String
    /// The `WidgetKind` of the Alert Widget
    public var kind: WidgetKind
    public var createdAt: Date
    public var publishedAt: Date?
    public var interactionTimeInterval: TimeInterval
    public var customData: String?
    public let programID: String

    let eventRecorder: EventRecorder
    
    // MARK: Private
    private let data: AlertCreated
    private let livelikeAPI: LiveLikeRestAPIServicable
    private let userProfile: UserProfile

    init(
        data: AlertCreated,
        eventRecorder: EventRecorder,
        livelikeAPI: LiveLikeRestAPIServicable,
        userProfile: UserProfile
    ) {
        self.data = data
        self.id = data.id
        self.kind = data.kind
        self.title = data.title
        self.programID = data.programId
        self.createdAt = data.createdAt
        self.publishedAt = data.publishedAt
        self.interactionTimeInterval = data.timeout.timeInterval
        self.linkURL = data.linkUrl
        self.imageURL = data.imageUrl
        self.text = data.text
        self.linkLabel = data.linkLabel
        self.customData = data.customData
        self.eventRecorder = eventRecorder
        self.livelikeAPI = livelikeAPI
        self.userProfile = userProfile
    }

    // MARK: Methods

    /// Opens the `linkURL` in a webpage if available.
    public func openLinkUrl() {
        if let widgetLink = linkURL {
            eventRecorder.record(.widgetEngaged(programID: programID, kind: kind, id: id))
            eventRecorder.record(.alertWidgetLinkOpened(alertId: data.id, programId: data.programId, linkUrl: widgetLink.absoluteString))
            UIApplication.shared.open(widgetLink)
        }
    }

    /// An `impression` is used to calculate user engagement on the Producer Site.
    /// Call this once when the widget is first displayed to the user.
    public func registerImpression(
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        self.eventRecorder.record(
            .widgetDisplayed(programID: programID, kind: kind.analyticsName, widgetId: id, widgetLink: linkURL)
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
    
    public func markAsInteractive() {
        self.eventRecorder.record(
            .widgetBecameInteractive(programID: programID, kind: kind, widgetID: id)
        )
    }

}
