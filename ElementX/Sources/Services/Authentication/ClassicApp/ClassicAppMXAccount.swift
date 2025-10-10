//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ClassicAppAccount {
    let userID: String
    let displayName: String?
    let serverName: String
    let cryptoStoreURL: URL
}

// MARK: NSCoding Types

class ClassicAppMXAccount: NSObject, NSCoding {
    /// The account's credentials: homeserver, access token, user ID.
    private(set) var credentials: Credentials
    /// The identity server URL.
    var identityServerURL: String
    /// The antivirus server URL, if any (nil by default).
    /// Set a non-null url to configure the antivirus scanner use.
    var antivirusServerURL: String?
    /// The Push Gateway URL used to send event notifications to (nil by default).
    /// This URL should be over HTTPS and never over HTTP.
    var pushGatewayURL: String?
    /// The 3PIDs linked to this account.
    /// [self load3PIDs] must be called to update the property.
    private(set) var threePIDs: [ClassicAppMXThirdPartyIdentifier]?
    /// The account user's device.
    /// [self loadDeviceInformation] must be called to update the property.
    private(set) var device: ClassicAppMXDevice?
    /// Transient information storage.
    private(set) var others = NSMutableDictionary()
    /// Flag to indicate that an APNS pusher has been set on the homeserver for this device.
    private(set) var hasPusherForPushNotifications = false
    
    /// The Push notification activity (based on PushKit) for this account.
    /// YES when Push is turned on (locally available and enabled homeserver side).
    var isPushKitNotificationActive: Bool {
        // This would typically have custom getter logic
        hasPusherForPushKitNotifications
    }
    
    /// Flag to indicate that a PushKit pusher has been set on the homeserver for this device.
    private(set) var hasPusherForPushKitNotifications = false
    /// Enable In-App notifications based on Remote notifications rules.
    /// NO by default.
    var enableInAppNotifications = false
    /// Disable the account without logging out (NO by default).
    ///
    /// A matrix session is automatically opened for the account when this property is toggled from YES to NO.
    /// The session is closed when this property is set to YES.
    var isDisabled = false
    /// Flag indicating if the end user has been warned about encryption and its limitations.
    var isWarnedAboutEncryption = false
    
    /// Flag to indicate if the account has been logged out by the homeserver admin.
    private(set) var isSoftLogout = false
    
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
        let homeserverURL = coder.decodeObject(forKey: Keys.homeserverURL) as? String
        let userID = coder.decodeObject(forKey: Keys.userID) as? String
        let accessToken = coder.decodeObject(forKey: Keys.accessToken) as? String
        
        credentials = Credentials(homeserver: homeserverURL,
                                  userID: userID,
                                  accessToken: accessToken)
        
        credentials.accessTokenExpiresAt = UInt64(coder.decodeInt64(forKey: Keys.accessTokenExpiresAt))
        credentials.refreshToken = coder.decodeObject(forKey: Keys.refreshToken) as? String
        credentials.identityServer = coder.decodeObject(forKey: Keys.identityServerURL) as? String
        credentials.identityServerAccessToken = coder.decodeObject(forKey: Keys.identityServerAccessToken) as? String
        credentials.deviceID = coder.decodeObject(forKey: Keys.deviceID) as? String
        credentials.allowedCertificate = coder.decodeObject(forKey: Keys.allowedCertificate) as? Data
        
        identityServerURL = credentials.identityServer ?? ""
        
        super.init()
        
        if let threePIDs = coder.decodeObject(forKey: Keys.threePIDs) as? [ClassicAppMXThirdPartyIdentifier] {
            self.threePIDs = threePIDs
        }
        
        if let device = coder.decodeObject(forKey: Keys.device) as? ClassicAppMXDevice {
            self.device = device
        }
        
        if let antivirusServerURL = coder.decodeObject(forKey: Keys.antivirusServerURL) as? String {
            self.antivirusServerURL = antivirusServerURL
        }
        
        if let pushGatewayURL = coder.decodeObject(forKey: Keys.pushGatewayURL) as? String {
            self.pushGatewayURL = pushGatewayURL
        }
        
        hasPusherForPushNotifications = coder.decodeBool(forKey: Keys.hasPusherForPushNotifications)
        hasPusherForPushKitNotifications = coder.decodeBool(forKey: Keys.hasPusherForPushKitNotifications)
        enableInAppNotifications = coder.decodeBool(forKey: Keys.enableInAppNotifications)
        
        isDisabled = coder.decodeBool(forKey: Keys.isDisabled)
        isSoftLogout = coder.decodeBool(forKey: Keys.isSoftLogout)
        
        isWarnedAboutEncryption = coder.decodeBool(forKey: Keys.isWarnedAboutEncryption)
        
        if let others = coder.decodeObject(forKey: Keys.others) as? NSMutableDictionary {
            self.others = others
        }
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
    
    /// The `MXCredentials` struct contains credentials to communicate with the Matrix
    /// Client-Server API.
    struct Credentials {
        /// The homeserver url (ex: "https://matrix.org").
        var homeserver: String?
        /// The identity server url (ex: "https://vector.im").
        var identityServer: String?
        /// The obtained user ID.
        var userID: String?
        /// The access token to create a MXRestClient
        var accessToken: String?
        /// The timestamp in milliseconds for when the access token will expire
        var accessTokenExpiresAt: UInt64 = 0
        /// The refresh token, which can be used to obtain new access tokens. (optional)
        var refreshToken: String?
        /// The access token to create a MXIdentityServerRestClient
        var identityServerAccessToken: String?
        /// The device ID.
        var deviceID: String?
        /// The server certificate trusted by the user (nil when the server is trusted by the device).
        var allowedCertificate: Data?
        /// The ignored server certificate (set when the user ignores a certificate change).
        var ignoredCertificate: Data?
        /// Additional data received during login process
        var loginOthers: [String: Any]?
        
        init(homeserver: String?, userID: String?, accessToken: String?) {
            self.homeserver = homeserver
            self.userID = userID
            self.accessToken = accessToken
        }
    }
}

/// `MXThirdPartyIdentifier` represents the response to /account/3pid GET request.
class ClassicAppMXThirdPartyIdentifier: NSObject, NSCoding {
    /// The medium of the third party identifier.
    var medium: String
    /// The third party identifier address.
    var address: String
    /// The timestamp in milliseconds when this 3PID has been validated.
    var validatedAt: UInt64
    /// The timestamp in milliseconds when this 3PID has been added to the user account.
    var addedAt: UInt64
    
    // MARK: NSCoding

    enum Keys {
        static let medium = "medium" // String
        static let address = "address" // String
        static let validatedAt = "validatedAt" // NSNumber?.uint64Value
        static let addedAt = "addedAt" // NSNumber?.uint64Value
    }

    required init?(coder aDecoder: NSCoder) {
        guard let medium = aDecoder.decodeObject(forKey: Keys.medium) as? String,
              let address = aDecoder.decodeObject(forKey: Keys.address) as? String else {
            return nil
        }
        
        self.medium = medium
        self.address = address

        if let validatedAtNumber = aDecoder.decodeObject(forKey: Keys.validatedAt) as? NSNumber {
            validatedAt = validatedAtNumber.uint64Value
        } else {
            validatedAt = 0
        }
        
        if let addedAtNumber = aDecoder.decodeObject(forKey: Keys.addedAt) as? NSNumber {
            addedAt = addedAtNumber.uint64Value
        } else {
            addedAt = 0
        }
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}

/// `MXDevice` represents a device of the current user.
class ClassicAppMXDevice: NSObject, NSCoding {
    /// A unique identifier of the device.
    var deviceID: String
    /// The display name set by the user for this device. Absent if no name has been set.
    var displayName: String?
    /// The IP address where this device was last seen. (May be a few minutes out of date, for efficiency reasons).
    var lastSeenIP: String?
    /// The timestamp (in milliseconds since the unix epoch) when this devices was last seen. (May be a few minutes out of date, for efficiency reasons).
    var lastSeenTimestamp: UInt64
    /// The latest recorded user agent for the device.
    var lastSeenUserAgent: String?
    
    // MARK: NSCoding

    enum Keys {
        static let deviceID = "device_id" // String
        static let displayName = "display_name" // String?
        static let lastSeenIP = "last_seen_ip" // String?
        static let lastSeenTimestamp = "last_seen_ts" // NSNumber?.uint64Value
        static let lastSeenUserAgent = "org.matrix.msc3852.last_seen_user_agent" // String?
    }

    required init?(coder aDecoder: NSCoder) {
        guard let deviceID = aDecoder.decodeObject(forKey: Keys.deviceID) as? String else {
            return nil
        }
        
        self.deviceID = deviceID
        displayName = aDecoder.decodeObject(forKey: Keys.displayName) as? String
        lastSeenIP = aDecoder.decodeObject(forKey: Keys.lastSeenIP) as? String
        lastSeenTimestamp = (aDecoder.decodeObject(forKey: Keys.lastSeenTimestamp) as? NSNumber)?.uint64Value ?? 0
        lastSeenUserAgent = aDecoder.decodeObject(forKey: Keys.lastSeenUserAgent) as? String
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}

/// `MXUser` represents a user in Matrix.
class ClassicAppMXUser: NSObject, NSCoding {
    /// The user id.
    private(set) var userID: String
    /// The user display name.
    var displayName: String?
    /// The url of the user of the avatar.
    var avatarURL: String?
    /// The user status.
    var statusMessage: String?
    
    /// Whether the user is currently active.
    /// If YES, lastActiveAgo is an approximation and "Now" should be shown instead.
    private(set) var currentlyActive = false
    /// The time in milliseconds since epoch the last activity by the user has
    /// been tracked by the home server.
    var lastActiveLocalTimestamp: UInt64 = 0
    /// Only when event.originServerTs > latestUpdateTS, we change displayname and avatarUrl.
    var latestUpdateTimestamp: UInt64 = 0
    
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
        avatarURL = aDecoder.decodeObject(forKey: Keys.avatarURL) as? String
        statusMessage = aDecoder.decodeObject(forKey: Keys.statusMessage) as? String
        currentlyActive = aDecoder.decodeBool(forKey: Keys.currentlyActive)
        // lastActiveLocalTimestamp = UInt64(aDecoder.decodeInt64(forKey: Keys.lastActiveLocalTimestamp))
        // latestUpdateTimestamp = UInt64(aDecoder.decodeInt64(forKey: Keys.latestUpdateTimestamp))
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}
