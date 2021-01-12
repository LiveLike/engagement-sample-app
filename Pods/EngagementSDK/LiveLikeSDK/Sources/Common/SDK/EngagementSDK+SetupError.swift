//
//  EngagementSDK+SetupError.swift
//  EngagementSDK
//

import Foundation

public extension EngagementSDK {
    /// Indicates an error after `EngagementSDK` initialization, before it could be used.
    enum SetupError: Error {
        /// Indicates that an invalid client ID was passed into the SDK.
        /// If received, check that this client id matches the one given in the Producer Site.
        case invalidClientID(String)

        /// Indicates that an internal server error occurred.
        /// If received, please try again later by creating a new `EngagementSDK` object or contact support@livelike.com.
        case internalServerError

        /// Indicates that an unknown error occurred. If received, please inspect the underlying error for more details.
        case unknownError(Error)

        /// Indicates that an invalid user access token
        /// If received, the EngagementSDK will continue to work but will not be associated to the expected user.
        case invalidUserAccessToken(String)
        
        /// Indicates that the custom api origin set may be invalid.
        case invalidAPIOrigin
    }
}

/// :nodoc:
extension EngagementSDK.SetupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidClientID(clientID):
            return "Failed to initialize the Engagement SDK due to a bad request. '\(clientID)' is not a valid client id. Check that this client id matches the one given in the Producer Site."

        case .internalServerError:
            return "Failed to initialize the Engagement SDK due to an internal server error. Please try again later or contact support@livelike.com."

        case let .unknownError(error):
            return "Failed to initialize the Engagement SDK due to an unknown error: \(error.localizedDescription)"

        case let .invalidUserAccessToken(userAccessToken):
            return "Failed to load user's profile with the user access token '\(userAccessToken)' because it was malformed or doesn't exist."
            
        case .invalidAPIOrigin:
            return "Failed to initialize the Engagement SDK due to a bad request. Please check that the custom api origin is correct."
        
        }
    }
}

/// :nodoc:
extension EngagementSDK.SetupError: CustomStringConvertible {
    public var description: String { return localizedDescription }
}

/// :nodoc:
extension EngagementSDK.SetupError: Equatable {
    public static func == (lhs: EngagementSDK.SetupError, rhs: EngagementSDK.SetupError) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidClientID(lhs), .invalidClientID(rhs)):
            return lhs == rhs

        case (.internalServerError, .internalServerError):
            return true

        case (.unknownError, .unknownError):
            return true

        case let (.invalidUserAccessToken(lhs), .invalidUserAccessToken(rhs)):
            return lhs == rhs

        default:
            return false
        }
    }
}

/// :nodoc:
extension EngagementSDK.SetupError: CustomNSError {
    public static var errorDomain: String { return "EngagementSDK.SetupError" }

    public var errorCode: Int {
        switch self {
        case .invalidClientID:
            return 1
        case .internalServerError:
            return 2
        case .unknownError:
            return 3
        case .invalidUserAccessToken:
            return 4
        case .invalidAPIOrigin:
            return 5
        }
    }

    public var errorUserInfo: [String: Any] {
        var userInfo = [
            NSLocalizedDescriptionKey: errorDescription as Any
        ]

        if case let .unknownError(error) = self {
            userInfo[NSUnderlyingErrorKey] = error
        }

        return userInfo
    }
}
