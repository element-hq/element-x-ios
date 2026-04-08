//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ClassicAppAccount: Equatable, CustomStringConvertible {
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    
    let serverName: String
    let homeserverURL: URL
    
    let cryptoStoreURL: URL
    let cryptoStorePassphrase: String
    
    let accessToken: String // For avatar loading and key backup detection.
    
    /// Custom `CustomStringConvertible` without the access token.
    var description: String {
        "ClassicAppAccount(userID: \(userID), homeserverURL: \(homeserverURL))"
    }
}

// MARK: NSCoding Types

final class ClassicAppMXAccount: NSObject, NSCoding {
    /// The obtained user ID.
    var userID: String
    /// The access token to create a MXRestClient.
    var accessToken: String
    /// The homeserver url (ex: "https://matrix.org").
    var homeserverURL: URL
    
    /// Disable the account without logging out (NO by default).
    ///
    /// A matrix session is automatically opened for the account when this property is toggled from YES to NO.
    /// The session is closed when this property is set to YES.
    let isDisabled: Bool
    /// Flag to indicate if the account has been logged out by the homeserver admin.
    let isSoftLogout: Bool
    
    /// Whether or not the account is considered active.
    var isActive: Bool {
        !isDisabled && !isSoftLogout
    }
    
    /// Override the existing `CustomStringConvertible` conformance.
    override var description: String {
        "ClassicAppMXAccount(userID: \(userID), homeserverURL: \(homeserverURL), isDisabled: \(isDisabled), isSoftLogout: \(isSoftLogout))"
    }
    
    // MARK: NSCoding
    
    enum Keys {
        static let homeserverURL = "homeserverurl" // String?
        static let userID = "userid" // String?
        static let accessToken = "accesstoken" // String?
        static let accessTokenExpiresAt = "accessTokenExpiresAt" // UInt64
        static let refreshToken = "refreshToken" // String?
        static let identityServerURL = "identityserverurl" // String?
        static let identityServerAccessToken = "identityserveraccesstoken" // String?
        static let deviceID = "deviceId" // String?
        static let allowedCertificate = "allowedCertificate" // Data?
        static let threePIDs = "threePIDs" // [MXThirdPartyIdentifier]?
        static let device = "device" // MXDevice?
        static let antivirusServerURL = "antivirusserverurl" // String?
        static let pushGatewayURL = "pushgatewayurl" // String?
        static let hasPusherForPushNotifications = "_enablePushNotifications" // Bool
        static let hasPusherForPushKitNotifications = "enablePushKitNotifications" // Bool
        static let enableInAppNotifications = "enableInAppNotifications" // Bool
        static let isDisabled = "disabled" // Bool
        static let isSoftLogout = "isSoftLogout" // Bool
        static let isWarnedAboutEncryption = "warnedAboutEncryption" // Bool
        static let others = "others" // NSMutableDictionary
    }
    
    required init?(coder: NSCoder) {
        guard let userID = coder.decodeObject(forKey: Keys.userID) as? String,
              let accessToken = coder.decodeObject(forKey: Keys.accessToken) as? String,
              let homeserver = coder.decodeObject(forKey: Keys.homeserverURL) as? String,
              let homeserverURL = URL(string: homeserver) else {
            return nil
        }
        
        self.userID = userID
        self.accessToken = accessToken
        self.homeserverURL = homeserverURL
        
        isDisabled = coder.decodeBool(forKey: Keys.isDisabled)
        isSoftLogout = coder.decodeBool(forKey: Keys.isSoftLogout)
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}

/// `MXUser` represents a user in Matrix.
final class ClassicAppMXUser: NSObject, NSCoding {
    /// The user id.
    let userID: String
    /// The user display name.
    let displayName: String?
    /// The url of the user of the avatar.
    let avatarURL: URL?
    
    // MARK: NSCoding
    
    enum Keys {
        static let userID = "userId" // String
        static let displayName = "displayname" // String?
        static let avatarURL = "avatarUrl" // String?
        static let statusMessage = "statusMsg" // String?
        static let currentlyActive = "currentlyActive" // Bool
        static let lastActiveLocalTimestamp = "lastActiveLocalTS" // UInt64
        static let latestUpdateTimestamp = "latestUpdateTS" // UInt64
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let userID = aDecoder.decodeObject(forKey: Keys.userID) as? String else {
            return nil
        }
        
        self.userID = userID
        displayName = aDecoder.decodeObject(forKey: Keys.displayName) as? String
        
        let avatarURLString = aDecoder.decodeObject(forKey: Keys.avatarURL) as? String
        avatarURL = avatarURLString.flatMap { URL(string: $0) }
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}
