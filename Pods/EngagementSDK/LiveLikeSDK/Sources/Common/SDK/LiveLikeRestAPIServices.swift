//
//  LiveLikeRestAPIServices.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 5/21/20.
//

import UIKit

/// Represents the different  pagination types that can be passed down to when working with Chat Room Membership
public enum ChatRoomMembershipPagination {
    case first
    case next
    case previous
}

protocol LiveLikeRestAPIServicable {
    var whenApplicationConfig: Promise<ApplicationConfiguration> { get }
    
    /// Retrieves a `ChatRoomResource` by chat room id
    func getChatRoomResource(roomID: String) -> Promise<ChatRoomResource>
    
    /// Creates a `ChatRoomResource`
    func createChatRoomResource(title: String?,
                                accessToken: AccessToken,
                                appConfig: ApplicationConfiguration) -> Promise<ChatRoomResource>
    
    /// Retrieve all the users who are members of a chat room
    func getChatRoomMemberships(roomID: String,
                                page: ChatRoomMembershipPagination,
                                accessToken: AccessToken) -> Promise<[ChatRoomMember]>
    
    /// Retrieve all Chat Rooms the current user is a member of
    func getUserChatRoomMemberships(profile: ProfileResource,
                                    accessToken: AccessToken,
                                    page: ChatRoomMembershipPagination) -> Promise<[ChatRoomInfo]>
   
    /// Create a membership between the current user and a Chat Room
    func createChatRoomMembership(roomID: String,
                                  accessToken: AccessToken) -> Promise<ChatRoomMember>
    
    func deleteChatRoomMembership(roomID: String,
                                  accessToken: AccessToken) -> Promise<Bool>
}
class LiveLikeRestAPIServices: LiveLikeRestAPIServicable {
    lazy var whenApplicationConfig: Promise<ApplicationConfiguration> =
        LiveLikeAPI.getApplicationConfiguration(apiBaseURL: self.apiBaseURL, clientID: self.clientID)
    
    private let apiBaseURL: URL
    private let clientID: String
    
    private struct ChatRoomMembershipPageUrls {
        var next: URL?
        var previous: URL?
    }
    
    private var userChatRoomMembershipUrls: ChatRoomMembershipPageUrls
    private var chatRoomMembershipUrls: ChatRoomMembershipPageUrls
    
    init(apiBaseURL: URL, clientID: String) {
        self.clientID = clientID
        self.apiBaseURL = apiBaseURL
        self.userChatRoomMembershipUrls = ChatRoomMembershipPageUrls()
        self.chatRoomMembershipUrls = ChatRoomMembershipPageUrls()
    }
    
    func getChatRoomResource(roomID: String) -> Promise<ChatRoomResource> {
        return firstly {
            whenApplicationConfig
        }.then { (appConfig: ApplicationConfiguration) in
            let stringToReplace = "{chat_room_id}"
            guard appConfig.chatRoomDetailUrlTemplate.contains(stringToReplace) else {
                return Promise(error: ContentSessionError.invalidChatRoomURLTemplate)
            }
            let urlTemplateFilled = appConfig.chatRoomDetailUrlTemplate.replacingOccurrences(of: stringToReplace, with: roomID)
            guard let chatRoomURL = URL(string: urlTemplateFilled) else {
                return Promise(error: ContentSessionError.invalidChatRoomURL)
            }
            let resource = Resource<ChatRoomResource>(get: chatRoomURL)
            return EngagementSDK.networking.load(resource)
        }
    }

    func createChatRoomResource(title: String?,
                                accessToken: AccessToken,
                                appConfig: ApplicationConfiguration) -> Promise<ChatRoomResource> {
        //swiftlint:disable nesting
        enum Error: Swift.Error, LocalizedError {
            case failedCreatingChatRoomUrl
            var errorDescription: String? { return "A url for creating chat rooms is corrupt" }
        }
        
        struct CreateChatRoomBody: Encodable {
            let title: String?
        }
        
        guard let createChatRoomURL = URL(string: appConfig.createChatRoomUrl) else {
            return Promise(error: Error.failedCreatingChatRoomUrl)
        }
        let createChatRoomBody = CreateChatRoomBody(title: title)
        let resource = Resource<ChatRoomResource>.init(url: createChatRoomURL,
                                                       method: .post(createChatRoomBody),
                                                       accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    func getChatRoomMemberships(roomID: String,
                                page: ChatRoomMembershipPagination,
                                accessToken: AccessToken) -> Promise<[ChatRoomMember]> {
        
        // Handle `.next`, `.previous` cases and their availibility
        var notFirstMembershipUrl: URL?
        switch page {
        case .first:
            // reset next/prev urls stored from previous calls to a different room
            self.chatRoomMembershipUrls = ChatRoomMembershipPageUrls()
        case .next:
            guard let nextPageUrl = self.chatRoomMembershipUrls.next  else {
                log.info("Next chat room membership page is unavailible")
                return Promise(value: [])
            }
            notFirstMembershipUrl = nextPageUrl
        case .previous:
            guard let previousPageUrl = self.chatRoomMembershipUrls.previous  else {
                log.info("Previous chat room membership page is unavailible")
                return Promise(value: [])
            }
            notFirstMembershipUrl = previousPageUrl
        }
        
        return firstly {
            self.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource -> Promise<ChatRoomMembershipPage> in
            let resource = Resource<ChatRoomMembershipPage>(get: notFirstMembershipUrl ?? chatRoomResource.membershipsUrl,
                                                            accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }.then { chatRoomMembershipPage in
            self.chatRoomMembershipUrls.next = chatRoomMembershipPage.next
            self.chatRoomMembershipUrls.previous = chatRoomMembershipPage.previous
            return Promise(value: chatRoomMembershipPage.results)
        }
    }
    
    func getUserChatRoomMemberships(profile: ProfileResource,
                                    accessToken: AccessToken,
                                    page: ChatRoomMembershipPagination) -> Promise<[ChatRoomInfo]> {
        
        // Handle `.next`, `.previous` cases and their availibility
        var notFirstMembershipUrl: URL?
        switch page {
        case .first:
            // reset next/prev urls stored from previous calls to a different room
            self.userChatRoomMembershipUrls = ChatRoomMembershipPageUrls()
        case .next:
            guard let nextPageUrl = self.userChatRoomMembershipUrls.next  else {
                log.info("Next chat room membership page is unavailible")
                return Promise(value: [])
            }
            notFirstMembershipUrl = nextPageUrl
        case .previous:
            guard let previousPageUrl = self.userChatRoomMembershipUrls.previous  else {
                log.info("Previous chat room membership page is unavailible")
                return Promise(value: [])
            }
            notFirstMembershipUrl = previousPageUrl
        }
        
        return firstly { () -> Promise<UserChatRoomMembershipPage> in
            let resource = Resource<UserChatRoomMembershipPage>(get: notFirstMembershipUrl ?? profile.chatRoomMembershipsUrl,
                                                                accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }.then { userChatMemberships in
            self.userChatRoomMembershipUrls.next = userChatMemberships.next
            self.userChatRoomMembershipUrls.previous = userChatMemberships.previous
            let chatRooms: [ChatRoomInfo] = userChatMemberships.results.map { ChatRoomInfo(id: $0.chatRoom.id,
                                                                                           title: $0.chatRoom.title) }
            return Promise(value: chatRooms)
        }
    }
    
    func createChatRoomMembership(roomID: String, accessToken: AccessToken) -> Promise<ChatRoomMember> {
        return firstly {
            self.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource -> Promise<ChatRoomMember> in
            let resource = Resource<ChatRoomMember>(
                url: chatRoomResource.membershipsUrl,
                method: .post(EmptyBody()),
                accessToken: accessToken.asString
            )
            return EngagementSDK.networking.load(resource)
        }.then { chatRoomMember in
            return Promise(value: chatRoomMember)
        }
    }
    
    func deleteChatRoomMembership(roomID: String, accessToken: AccessToken) -> Promise<Bool> {
        return firstly {
            self.getChatRoomResource(roomID: roomID)
        }.then { chatRoomResource -> Promise<Bool> in
            let resource = Resource<Bool>(
                url: chatRoomResource.membershipsUrl,
                method: .delete(EmptyBody()),
                accessToken: accessToken.asString
            )
            return EngagementSDK.networking.load(resource)
        }.then { chatRoomMember in
            return Promise(value: chatRoomMember)
        }
    }
}
