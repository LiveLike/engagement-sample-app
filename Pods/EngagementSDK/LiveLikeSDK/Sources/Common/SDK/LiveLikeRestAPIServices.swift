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

struct ChatRoomMembershipsResult {
    let members: [ChatRoomMember]
    let next: URL?
    let previous: URL?
}

struct UserChatRoomMembershipsResult {
    let chatRooms: [ChatRoomInfo]
    let next: URL?
    let previous: URL?
}

/// Represents the different  pagination types that can be passed down to when working with paginated calls
public enum Pagination {
    case first
    case next
    case previous
}

// MARK: - Decodables

/// Wraps a Decodable as an optional
/// Useful for decoding collections of dynamic objects which may fail and throw an error
public struct OptionalObject<Base: Decodable>: Decodable {
    public let value: Base?

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self.value = try container.decode(Base.self)
        } catch {
            log.error(error)
            self.value = nil
        }
    }
}

/// A generic result type that can be used when parsing paginated results from backend
struct PaginatedResource<Element: Decodable>: Decodable {
    internal init(previous: URL?, count: Int, next: URL?, results: [Element]) {
        self.previous = previous
        self.count = count
        self.next = next
        self.results = results
    }
    
    let previous: URL?
    let count: Int
    let next: URL?
    let results: [Element]

    enum CodingKeys: CodingKey {
        case previous
        case count
        case next
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.previous = try container.decode(URL?.self, forKey: .previous)
        self.next = try container.decode(URL?.self, forKey: .next)
        self.count = try container.decode(Int.self, forKey: .count)
        // compactMaps unexpected or corrupt elements
        self.results = try container.decode([OptionalObject<Element>].self, forKey: .results).compactMap { $0.value }
    }
}

struct RewardItemResource: Decodable {
    let id: String
    let url: URL
    let clientId: String
    let name: String
}

struct RewardResource: Decodable {
    let rewardItemId: String
    var newRank: Int
    var rewardItemAmount: Int
    var newScore: Int
    var newPercentileRank: String
    var leaderboardId: String
    var rewardAction: RewardActionResource

    enum CodingKeys: String, CodingKey {
        case rewardItemId
        case newRank
        case rewardItemAmount
        case newScore
        case newPercentileRank
        case leaderboardId
        case rewardAction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rewardItemId = try container.decode(String.self, forKey: .rewardItemId)
        newRank = try container.decode(Int.self, forKey: .newRank)
        rewardItemAmount = try container.decode(Int.self, forKey: .rewardItemAmount)
        newScore = try container.decode(Int.self, forKey: .newScore)
        newPercentileRank = try container.decode(String.self, forKey: .newPercentileRank)
        leaderboardId = try container.decode(String.self, forKey: .leaderboardId)
        if let rewardAction = try? container.decode(RewardActionResource.self, forKey: .rewardAction) {
            self.rewardAction = rewardAction
        } else {
            self.rewardAction = .undefined
        }
    }

}

enum RewardActionResource: String, Decodable {
    case pollVoted = "poll-voted"
    case predictionMade = "prediction-made"
    case predictionCorrect = "prediction-correct"
    case quizAnswered = "quiz-answered"
    case quizCorrect = "quiz-correct"
    case undefined
}

struct ClaimRewardResource: Decodable {
    let rewards: [RewardResource]
}

struct CheerMeterVoteResponse: Decodable {
    let rewards: [RewardResource]
    let voteCount: Int
    let optionId: String
}

struct PredictionVoteResource: Decodable {
    let id: String
    let url: URL
    let optionId: String
    let rewards: [RewardResource]
    let claimToken: String
}

struct PollVoteResource: Decodable {
    let id: String
    let url: URL
    let optionId: String
    let rewards: [RewardResource]
}

struct ImageSliderVoteResource: Decodable {
    let id: String
    let rewards: [RewardResource]
}

// MARK: - Encodables

struct CreateChatRoomBody: Encodable {
    let title: String?
    let visibility: String
}

struct CheerMeterVote: Encodable {
    let voteCount: Int
}

protocol LiveLikeRestAPIServicable {
    var whenApplicationConfig: Promise<ApplicationConfiguration> { get }
    
    func getProgramDetail(programID: String) -> Promise<ProgramDetailResource>
    
    /// Retrieves a `ChatRoomResource` by chat room id
    func getChatRoomResource(roomID: String, accessToken: AccessToken) -> Promise<ChatRoomResource>
    
    /// Creates a `ChatRoomResource`
    func createChatRoomResource(
        title: String?,
        visibility: ChatRoomVisibilty,
        accessToken: AccessToken,
        appConfig: ApplicationConfiguration
    ) -> Promise<ChatRoomResource>
    
    /// Retrieve all the users who are members of a chat room
    func getChatRoomMemberships(url: URL,
                                accessToken: AccessToken) -> Promise<ChatRoomMembershipsResult>
    
    /// Retrieve all Chat Rooms the current user is a member of
    func getUserChatRoomMemberships(url: URL,
                                    accessToken: AccessToken,
                                    page: ChatRoomMembershipPagination) -> Promise<UserChatRoomMembershipsResult>
   
    /// Create a membership between the current user and a Chat Room
    func createChatRoomMembership(roomID: String,
                                  accessToken: AccessToken) -> Promise<ChatRoomMember>
    
    func deleteChatRoomMembership(roomID: String,
                                  accessToken: AccessToken) -> Promise<Bool>
    
    func getChatUserMutedStatus(profileID: String, roomID: String, accessToken: AccessToken) -> Promise<ChatUserMuteStatusResource>
    
    /// Get widget details of a widget
    func getWidget(id: String, kind: WidgetKind) -> Promise<WidgetResource>
    
    /// Get leaderboards for a program ID
    func getLeaderboards(programID: String) -> Promise<[LeaderboardResource]>
    
    /// Get leaderboard object by ID
    func getLeaderboard(leaderboardID: String) -> Promise<LeaderboardResource>
    
    /// Get a paginated list of leaderboard entries
    func getLeaderboardEntries(url: URL, accessToken: AccessToken) -> Promise<PaginatedResource<LeaderboardEntryResource>>

    func getLeaderboardEntry(url: URL, accessToken: AccessToken) -> Promise<LeaderboardEntryResource>
    
    /// Get a leaderboard entry profile
    func getLeaderboardProfile(url: URL, accessToken: AccessToken) -> Promise<LeaderboardEntryResource>

    func getRewardItems(url: URL, accessToken: AccessToken) -> Promise<[RewardItemResource]>

    func claimRewards(claimURL: URL, claimToken: String, accessToken: AccessToken) -> Promise<ClaimRewardResource>

    /// Create a new user profile
    func createProfile(profileURL: URL) -> Promise<AccessToken>

    /// Update the nickname of a user profile
    func setNickname(profileURL: URL, nickname: String, accessToken: AccessToken) -> Promise<ProfileResource>

    /// Get a user profile
    func getProfile(profileURL: URL, accessToken: AccessToken) -> Promise<ProfileResource>
    
    func createCheerMeterVote(voteCount: Int, voteURL: URL, accessToken: AccessToken) -> Promise<CheerMeterVoteResponse>

    func getTimeline(timelineURL: URL, accessToken: AccessToken) -> Promise<PaginatedResource<WidgetResource>>

    func createImpression(impressionURL: URL, userSessionID: String, accessToken: AccessToken) -> Promise<ImpressionResponse>

    func createQuizAnswer(answerURL: URL, accessToken: AccessToken) -> Promise<QuizVote>

    func createPredictionVote(voteURL: URL, accessToken: AccessToken) -> Promise<PredictionVoteResource>
    
    func createVoteOnPoll(for optionURL: URL, accessToken: AccessToken) -> Promise<PollVoteResource>
    
    func updateVoteOnPoll(for optionID: String, optionURL: URL, accessToken: AccessToken) -> Promise<PollVoteResource>

    func createImageSliderVote(voteURL: URL, magnitude: Double, accessToken: AccessToken) -> Promise<ImageSliderVoteResource>
}

class LiveLikeRestAPIServices: LiveLikeRestAPIServicable {

    func createCheerMeterVote(voteCount: Int, voteURL: URL, accessToken: AccessToken) -> Promise<CheerMeterVoteResponse> {
        let vote = CheerMeterVote(voteCount: voteCount)
        let resource = Resource<CheerMeterVoteResponse>(url: voteURL, method: .post(vote), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }

    func getProgramDetail(programID: String) -> Promise<ProgramDetailResource> {
        let programDetailVendor = ProgramDetailClient(programID: programID, applicationVendor: self)
        return programDetailVendor.getProgramDetails()
    }
    
    func getWidget(id: String, kind: WidgetKind) -> Promise<WidgetResource> {
        return firstly {
            whenApplicationConfig
        }.then { appConfig -> Promise<URL> in
            var widgetDetailStringUrl = appConfig.widgetDetailUrlTemplate.replacingOccurrences(
                of: "{kind}",
                with: kind.stringValue
            )
            widgetDetailStringUrl = widgetDetailStringUrl.replacingOccurrences(of: "{id}", with: id)
            
            guard let widgetDetailUrl = URL(string: widgetDetailStringUrl) else {
                return Promise(error: GetWidgetAPIServicesError.widgetUrlIsCorrupt)
            }
            
            return Promise(value: widgetDetailUrl)
        }.then { widgetDetailUrl in
            let resource = Resource<WidgetResource>(get: widgetDetailUrl)
            return EngagementSDK.networking.load(resource)
        }
    }
    
    var whenApplicationConfig: Promise<ApplicationConfiguration>

    private let apiBaseURL: URL
    private let clientID: String
    
    init(apiBaseURL: URL, clientID: String) {
        self.clientID = clientID
        self.apiBaseURL = apiBaseURL

        self.whenApplicationConfig = {
            let url = apiBaseURL.appendingPathComponent("applications").appendingPathComponent(clientID)
            let resource = Resource<ApplicationConfiguration>(get: url)
            return EngagementSDK.networking.load(resource)
        }()
    }
    
    func getChatRoomResource(roomID: String, accessToken: AccessToken) -> Promise<ChatRoomResource> {
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
            let resource = Resource<ChatRoomResource>(get: chatRoomURL, accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }
    }

    func createChatRoomResource(
        title: String?,
        visibility: ChatRoomVisibilty,
        accessToken: AccessToken,
        appConfig: ApplicationConfiguration
    ) -> Promise<ChatRoomResource> {

        guard let createChatRoomURL = URL(string: appConfig.createChatRoomUrl) else {
            return Promise(error: CreateChatRoomResourceError.failedCreatingChatRoomUrl)
        }
        let createChatRoomBody = CreateChatRoomBody(
            title: title,
            visibility: visibility.rawValue
        )
        let resource = Resource<ChatRoomResource>.init(
            url: createChatRoomURL,
            method: .post(createChatRoomBody),
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }
    
    func getChatRoomMemberships(url: URL,
                                accessToken: AccessToken) -> Promise<ChatRoomMembershipsResult> {
        return firstly { () -> Promise<ChatRoomMembershipPage> in
            let resource = Resource<ChatRoomMembershipPage>(get: url,
                                                            accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }.then { chatRoomMembershipPage in
            return Promise(value: ChatRoomMembershipsResult(members: chatRoomMembershipPage.results,
                                                            next: chatRoomMembershipPage.next,
                                                            previous: chatRoomMembershipPage.previous))
        }
    }
    
    func getUserChatRoomMemberships(url: URL,
                                    accessToken: AccessToken,
                                    page: ChatRoomMembershipPagination) -> Promise<UserChatRoomMembershipsResult> {
        return firstly { () -> Promise<UserChatRoomMembershipPage> in
            let resource = Resource<UserChatRoomMembershipPage>(get: url,
                                                                accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }.then { userChatMemberships in
            let chatRooms: [ChatRoomInfo] = userChatMemberships.results.map { ChatRoomInfo(id: $0.chatRoom.id,
                                                                                           title: $0.chatRoom.title, visibility: $0.chatRoom.visibility) }
            return Promise(value: UserChatRoomMembershipsResult(chatRooms: chatRooms,
                                                                next: userChatMemberships.next,
                                                                previous: userChatMemberships.previous))
        }
    }
    
    func createChatRoomMembership(roomID: String, accessToken: AccessToken) -> Promise<ChatRoomMember> {
        return firstly {
            self.getChatRoomResource(roomID: roomID, accessToken: accessToken)
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
            self.getChatRoomResource(roomID: roomID, accessToken: accessToken)
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
    
    func getChatUserMutedStatus(profileID: String, roomID: String, accessToken: AccessToken) -> Promise<ChatUserMuteStatusResource> {
        return firstly {
            self.getChatRoomResource(roomID: roomID, accessToken: accessToken)
        }.then { chatRoomResource -> Promise<ChatUserMuteStatusResource> in
            
            let stringToReplace = "{profile_id}"
            guard chatRoomResource.mutedStatusUrlTemplate.contains(stringToReplace) else {
                return Promise(error: ContentSessionError.invalidUserMutedStatusURLTemplate)
            }
            let urlTemplateFilled = chatRoomResource.mutedStatusUrlTemplate.replacingOccurrences(of: stringToReplace, with: profileID)
            guard let chatUserMutedStatusURL = URL(string: urlTemplateFilled) else {
                return Promise(error: ContentSessionError.invalidUserMutedStatusURL)
            }
            let resource = Resource<ChatUserMuteStatusResource>(get: chatUserMutedStatusURL)
            return EngagementSDK.networking.load(resource)
        }
    }
    
    func getLeaderboards(programID: String) -> Promise<[LeaderboardResource]> {
        return firstly {
            getProgramDetail(programID: programID)
        }.then { program -> Promise<[LeaderboardResource]>in
            return Promise(value: program.leaderboards)
        }
    }
    
    func getLeaderboard(leaderboardID: String) -> Promise<LeaderboardResource> {
        return firstly {
            whenApplicationConfig
        }.then { (appConfig: ApplicationConfiguration) in
            let stringToReplace = "{leaderboard_id}"
            guard appConfig.leaderboardDetailUrlTemplate.contains(stringToReplace) else {
                return Promise(error: LLGamificationError.leaderboardDetailUrlCorrupt)
            }
            let urlTemplateFilled = appConfig.leaderboardDetailUrlTemplate.replacingOccurrences(of: stringToReplace,
                                                                                                with: leaderboardID)
            guard let leaderboardURL = URL(string: urlTemplateFilled) else {
                return Promise(error: LLGamificationError.leaderboardUrlCreationFailure)
            }
            let resource = Resource<LeaderboardResource>(get: leaderboardURL)
            return EngagementSDK.networking.load(resource)
        }
    }
    
    func getLeaderboardEntries(url: URL, accessToken: AccessToken) -> Promise<PaginatedResource<LeaderboardEntryResource>> {
        return firstly { () -> Promise<PaginatedResource<LeaderboardEntryResource>> in
            let resource = Resource<PaginatedResource<LeaderboardEntryResource>>(get: url,
                                                                           accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }
    }

    func getLeaderboardEntry(url: URL, accessToken: AccessToken) -> Promise<LeaderboardEntryResource> {
        let resource = Resource<LeaderboardEntryResource>(get: url, accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    func getLeaderboardProfile(url: URL, accessToken: AccessToken) -> Promise<LeaderboardEntryResource> {
        return firstly { () -> Promise<LeaderboardEntryResource> in
            let resource = Resource<LeaderboardEntryResource>(get: url,
                                                        accessToken: accessToken.asString)
            return EngagementSDK.networking.load(resource)
        }
    }

    func getRewardItems(url: URL, accessToken: AccessToken) -> Promise<[RewardItemResource]> {
        //swiftlint:disable nesting
        struct RewardItems: Decodable {
            let results: [RewardItemResource]
        }

        let resource = Resource<RewardItems>(
            get: url,
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource).then{ $0.results }
    }

    func claimRewards(claimURL: URL, claimToken: String, accessToken: AccessToken) -> Promise<ClaimRewardResource> {
        //swiftlint:disable nesting
        struct Payload: Encodable {
            let claimToken: String
        }
        let resource = Resource<ClaimRewardResource>(
            url: claimURL,
            method: .post(Payload(claimToken: claimToken)),
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }

    func createProfile(profileURL: URL) -> Promise<AccessToken> {
        struct AccessTokenResource: Decodable {
            let accessToken: String
        }
        let resource = Resource<AccessTokenResource>(
            url: profileURL,
            method: .post(EmptyBody())
        )
        return firstly {
            EngagementSDK.networking.load(resource)
        }.then {
            AccessToken(fromString: $0.accessToken)
        }
    }

    func setNickname(profileURL: URL, nickname: String, accessToken: AccessToken) -> Promise<ProfileResource> {
        //swiftlint:disable nesting
        struct NicknamePatchBody: Encodable {
            let nickname: String
        }
        //swiftlint:enable nesting

        let body = NicknamePatchBody(nickname: nickname)
        let resource = Resource<ProfileResource>(
            url: profileURL,
            method: .patch(body),
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }

    func getProfile(profileURL: URL, accessToken: AccessToken) -> Promise<ProfileResource> {
        let resource = Resource<ProfileResource>(
            get: profileURL,
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }

    func getTimeline(timelineURL: URL, accessToken: AccessToken) -> Promise<PaginatedResource<WidgetResource>> {
        let resource = Resource<PaginatedResource<WidgetResource>>(
            get: timelineURL,
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }

    func createImpression(impressionURL: URL, userSessionID: String, accessToken: AccessToken) -> Promise<ImpressionResponse> {
        //swiftlint:disable nesting
        struct ImpressionBody: Encodable {
            var sessionId: String
        }
        let resource = Resource<ImpressionResponse>(
            url: impressionURL,
            method: .post(ImpressionBody(sessionId: userSessionID)),
            accessToken: accessToken.asString
        )
        return EngagementSDK.networking.load(resource)
    }

    func createQuizAnswer(answerURL: URL, accessToken: AccessToken) -> Promise<QuizVote> {
        let resource = Resource<QuizVote>(url: answerURL, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }

    func createPredictionVote(voteURL: URL, accessToken: AccessToken) -> Promise<PredictionVoteResource> {
        let resource = Resource<PredictionVoteResource>(url: voteURL, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    func createVoteOnPoll(for optionURL: URL, accessToken: AccessToken) -> Promise<PollVoteResource> {
        let resource = Resource<PollVoteResource>(url: optionURL, method: .post(EmptyBody()), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
    
    func updateVoteOnPoll(for optionID: String, optionURL: URL, accessToken: AccessToken) -> Promise<PollVoteResource> {
        let voteBody = VoteBody(optionId: optionID)
        let resource = Resource<PollVoteResource>(url: optionURL, method: .patch(voteBody), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }

    func createImageSliderVote(voteURL: URL, magnitude: Double, accessToken: AccessToken) -> Promise<ImageSliderVoteResource> {
        struct ImageSliderVote: Encodable {
            let magnitude: String
        }
        let magnitudeString = String(format: "%.3f", magnitude) // Server expects <= 3 decimal places
        let vote = ImageSliderVote(magnitude: magnitudeString)
        let resource = Resource<ImageSliderVoteResource>(url: voteURL, method: .post(vote), accessToken: accessToken.asString)
        return EngagementSDK.networking.load(resource)
    }
}
