//
//  LiveLikeErrors.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 7/29/20.
//

import PubNub
import Foundation

// MARK: - CHAT
enum PubNubChannelError: LocalizedError {
    case failedToSerializeHistoryToJsonData
    case pubnubStatusError(errorStatus: PNErrorStatus)
    case foundNoResultsFromHistoryRequest
    case foundNoResultsForChannel(channel: String)
    case messageActionAlreadyAdded
    case messageActionDoesntExist
    case failedToSendMessageAction
    case failedToRemoveMessageAction
    case expectedPubSubIDInternalToBeNSNumber
    case foundNoAction
    case noMessageCountResult
    case noMessageCountForChannel(channel: String)
    case sendMessageFailedAccessDenied

    var errorDescription: String? {
        switch self {
        case .failedToSerializeHistoryToJsonData:
            return "Failed to serialize the PubNub history result as json data."
        case .pubnubStatusError(let errorStatus):
            return errorStatus.errorData.information
        case .foundNoResultsFromHistoryRequest:
            return "Failed to find results for history request."
        case .foundNoResultsForChannel(let channel):
            return "Didn't find any results for channel \(channel)"
        case .messageActionAlreadyAdded:
            return "Failed to send the message action because it already exists."
        case .messageActionDoesntExist:
            return "Failed to remove the message action because it doesn't exist."
        case .failedToSendMessageAction:
            return "Failed to send the message action."
        case .failedToRemoveMessageAction:
            return "Failed to remove the message action."
        case .expectedPubSubIDInternalToBeNSNumber:
            return "Expected the pub sub id internal to be type NSNumber."
        case .foundNoAction:
            return "Failed to receive an action"
        case .noMessageCountResult:
            return "Message count request returned nil result."
        case .noMessageCountForChannel(let channel):
            return "Message count for channel \(channel) not found in dictionary."
        case .sendMessageFailedAccessDenied:
            return "Sending Message Failed - Access Denied"
        }
    }
}

enum PubNubServiceError: LocalizedError {
    case failedToParseHistoryResultAsJsonData
    case pubnubStatusError(errorStatus: PNErrorStatus)

    var errorDescription: String? {
        switch self {
        case .failedToParseHistoryResultAsJsonData:
            return "Failed to parse the history result as json data."
        case .pubnubStatusError(let errorStatus):
            return errorStatus.errorData.information
        }
    }
}

enum ProgramChatReactionVendorError: LocalizedError {
    case invalidReactionPacksURL

    var errorDescription: String? {
        switch self {
        case .invalidReactionPacksURL:
            return "Invalid Reaction Packs URL"
        }
    }
}

enum PubSubChatRoomError: LocalizedError {
    case invalidUserChatRoomImageUrl
    case failedToEncodeChatMessage
    case sendMessageFailedNoNickname
    case failedToFindPubSubID(messageID: ChatMessageID)
    case reactionIdInternalNotPubSubID
    case failedToFindChatMessageForPubSubID(pubsubID: PubSubID)
    case failedToFindReportedChatMessage(messageId: String)
    case promiseRejectedDueToNilSelf
    case failedToSendImageDueToMissingData
    case failedDueToMissingMessageReporter

    var errorDescription: String? {
        switch self {
        case .invalidUserChatRoomImageUrl:
            return "The user chat image url provided is not valid"
        case .failedToEncodeChatMessage:
            return "The SDK failed to decode the chat message to json."
        case .sendMessageFailedNoNickname:
            return "The SDK failed to send the message because there is no user nickname set."
        case .failedToFindPubSubID(let messageID):
            return "Failed to find PubSubID for message with id: \(messageID)"
        case .reactionIdInternalNotPubSubID:
            return "Failed because internal id of reaction is not of type PubSubID"
        case .failedToFindChatMessageForPubSubID(let pubsubID):
            return "Failed to find the ChatMessageType for pubsub message with id: \(pubsubID)"
        case .failedToFindReportedChatMessage(let messageId):
        return "Failed to find message that is being reported with id: \(messageId)"
        case .promiseRejectedDueToNilSelf:
            return "Promise rejected due to self being nil"
        case .failedToSendImageDueToMissingData:
            return "Failed to send image message because expected imageData cannot be retrieved from cache."
        case .failedDueToMissingMessageReporter:
        return "Failed to report a message because the message reporter has not been found"
        }
    }
}

enum PubSubChatRoomDecodeError: LocalizedError {
    case failedToDecodePayload(decodingError: String)
    case missingPayload
    
    var errorDescription: String? {
        switch self {
        case .failedToDecodePayload(let decodingError):
            return "\(decodingError)"
        case .missingPayload:
            return "'payload' is missing from PubSubChatEventWithPayload"
        }
    }
    
}

enum CreateChatRoomResourceError: Swift.Error, LocalizedError {
    case failedCreatingChatRoomUrl
    var errorDescription: String? { return "A url for creating chat rooms is corrupt" }
}

// MARK: - WIDGET
enum GetWidgetError: Swift.Error, LocalizedError {
    case widgetDoesNotExist
    var errorDescription: String? { return "Widget does not exist" }
}

enum GetWidgetAPIServicesError: Swift.Error, LocalizedError {
   case widgetUrlIsCorrupt
   var errorDescription: String? { return "Widget API url is corrupt" }
}

enum MessagingClientError: Swift.Error, LocalizedError {
    case invalidEvent(event: String)
    var errorDescription: String? {
        switch self {
        case let .invalidEvent(event):
            return event
        }
    }
}

enum PredictionFollowUpModelErrors: LocalizedError {
    case couldNotFindVote
    case concurrentGetVote
    case claimTokenNotFound
}

enum PollWidgetModelError: Swift.Error, LocalizedError {
    case voteAlreadySubmitted
    case failedDueToInvalidOptionID
    case failedUpdatingVote(String)
    var errorDescription: String? {
        switch self {
        case .voteAlreadySubmitted:
            return "Poll vote already submitted"
        case .failedDueToInvalidOptionID:
            return "Vote failed due to invalid Option ID"
        case .failedUpdatingVote(let errorMsg):
            return "Failed updating vote for reason: \(errorMsg)"
        }
    }
}

// MARK: - GAMIFICATION
enum LLGamificationError: LocalizedError {
    case noNextLeaderboardEntries
    case noPreviousLeaderboardEntries
    case leaderboardUrlCreationFailure
    case leaderboardDetailUrlCorrupt

    var errorDescription: String? {
        switch self {
        case .noNextLeaderboardEntries:
            return "Next leaderboard entries page is unavailable"
        case .noPreviousLeaderboardEntries:
            return "Previous leaderboard entries page is unavailable"
        case .leaderboardUrlCreationFailure:
            return "Leaderboard URL failed to be created"
        case .leaderboardDetailUrlCorrupt:
            return "Leaderboard Detail URL is corrupt"
        }
    }
}

// MARK: - NETWORK
enum ImageUploaderError: LocalizedError {
    case failedToGetJPEG
    case noDataInResponse
    case failedToDecodeDataAsImageResource
}

enum ProgramDetailsError: Swift.Error, LocalizedError {
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let urlString):
            return "Failed to construct the program url \(urlString). Check that the template and program id are valid."
        }
    }
}

enum SetUserDisplayNameError: Swift.Error, LocalizedError {
    case invalidNameLength
    var errorDescription: String? { return "Display names must be between 1 and 20 characters" }
}

enum UIImageDownloadError: Error {
    case error(description: String)
}

enum NetworkClientError: Error {
    case invalidResponse(description: String)
    case internalServerError
    case badRequest
    case notFound404
    case noData
    case decodingError(Error)
    case forbidden
    case unauthorized
    case badDeleteResponseType
}

enum StickerRepositoryError: Error {
    case invalidURL
}

// MARK: - MISC
enum CacheError: LocalizedError {
    case nilObjectFoundInCache
    case promiseRejectedDueToNilSelf

    var errorDescription: String? {
        switch self {
        case .nilObjectFoundInCache:
            return "Disk cache found object but it was nil"
        case .promiseRejectedDueToNilSelf:
            return "Promise rejected due to self being nil"
        }
    }
}

enum AnalyticsError: LocalizedError {
    case noTokenProvidedForMixpanel
    
    var errorDescription: String? {
        switch self {
        case .noTokenProvidedForMixpanel:
        return "Will not initialize Mixpanel because no token available."
        }
    }
}

enum ContentSessionError: LocalizedError {
    case invalidChatRoomURLTemplate
    case invalidChatRoomURL
    case invalidUserMutedStatusURLTemplate
    case invalidUserMutedStatusURL
    case missingChatService
    case missingChatRoomResourceFields
    case failedSettingsChatSessionDelegate
    case failedLoadingInitialChat
    case missingWidgetClient
    case missingSubscribeChannel
    case missingChatRoom(placeOfError: String)
    case failedToCreateWidgetModelMismatchedProgramID(widgetProgramID: String, sessionProgramID: String)

    var errorDescription: String? {
        switch self {
        case .invalidChatRoomURLTemplate:
            return "The template provided to build a chat room url is invalid or incompatible. Expected replaceable string of '{chat_room_id}'."
        case .invalidChatRoomURL:
            return "The chat room resource url is not a valid URL."
        case .missingChatRoomResourceFields:
            return "Failed to initalize Chat because of missing required fields on the chat room resource."
        case .missingChatService:
            return "Failed to initialize Chat because the service is missing."
        case .failedSettingsChatSessionDelegate:
            return "Failed setting the Chat Session Delegate"
        case .missingWidgetClient:
            return "Failed creating Widget Queue due to a missing Widget Client"
        case .missingSubscribeChannel:
            return "Failed creating Widget Queue due to a missing Subscribe Channel"
        case .missingChatRoom(let placeOfError):
            return "Failed \(placeOfError) due to a missing Chat Room"
        case .failedLoadingInitialChat:
            return "Failed loading initial history for chat"
        case .failedToCreateWidgetModelMismatchedProgramID(let widgetProgramID, let sessionProgramID):
            return "Failed to create the Widget Model because the program id of the widget (\(widgetProgramID)) doesn't match the Content Session (\(sessionProgramID))"
        case .invalidUserMutedStatusURLTemplate:
            return "The template provided to build user muted status url is invalid or incompatible. Expected replaceable string of '{profile_id}'."
        case .invalidUserMutedStatusURL:
            return "The user muted status resource url is not a valid URL."
        }
    }
}

enum SessionError: Error, LocalizedError {
    case messagingClientsNotConfigured
    case invalidSessionStatus(SessionStatus)

    var errorDescription: String? {
        switch self {
        case .messagingClientsNotConfigured:
            return "No messaging clients have been configured"
        case let .invalidSessionStatus(status):
            return "Could not complete request. Invalid session status \(status)"
        }
    }
}

enum MediaRepositoryError: Error {
   case downloadFailedWithNoError
   case mediaNotUIImage
}

enum ThemeErrors: Error {
    case unsupportedBackgroundProperty
    case invalidColorValue
}
