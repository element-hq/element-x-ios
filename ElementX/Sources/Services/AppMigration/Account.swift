//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The `MXCredentials` struct contains credentials to communicate with the Matrix
/// Client-Server API.
struct MXCredentials {
    /// The homeserver url (ex: "https://matrix.org").
    var homeServer: String?
    
    /// The identity server url (ex: "https://vector.im").
    var identityServer: String?
    
    /// The obtained user id.
    var userId: String?
    
    /// The access token to create a MXRestClient
    var accessToken: String?
    
    /// The timestamp in milliseconds for when the access token will expire
    var accessTokenExpiresAt: UInt64 = 0
    
    /// The refresh token, which can be used to obtain new access tokens. (optional)
    var refreshToken: String?
    
    /// The access token to create a MXIdentityServerRestClient
    var identityServerAccessToken: String?
    
    /// The device id.
    var deviceId: String?
    
    /// The server certificate trusted by the user (nil when the server is trusted by the device).
    var allowedCertificate: Data?
    
    /// The ignored server certificate (set when the user ignores a certificate change).
    var ignoredCertificate: Data?
    
    /// Additional data received during login process
    var loginOthers: [String: Any]?
    
    init(homeServer: String?, userId: String?, accessToken: String?) {
        self.homeServer = homeServer
        self.userId = userId
        self.accessToken = accessToken
    }
}

/// `MXThirdPartyIdentifier` represents the response to /account/3pid GET request.
class MXThirdPartyIdentifier: NSObject, NSCoding {
    /// The medium of the third party identifier.
    var medium: String
    
    /// The third party identifier address.
    var address: String
    
    /// The timestamp in milliseconds when this 3PID has been validated.
    var validatedAt: UInt64
    
    /// The timestamp in milliseconds when this 3PID has been added to the user account.
    var addedAt: UInt64
    
    required init?(coder aDecoder: NSCoder) {
        guard let medium = aDecoder.decodeObject(forKey: "medium") as? String,
              let address = aDecoder.decodeObject(forKey: "address") as? String else {
            return nil
        }
        
        self.medium = medium
        self.address = address

        if let validatedAtNumber = aDecoder.decodeObject(forKey: "validatedAt") as? NSNumber {
            validatedAt = validatedAtNumber.uint64Value
        } else {
            validatedAt = 0
        }
        
        if let addedAtNumber = aDecoder.decodeObject(forKey: "addedAt") as? NSNumber {
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
class MXDevice: NSObject, NSCoding {
    /// A unique identifier of the device.
    var deviceId: String
    
    /// The display name set by the user for this device. Absent if no name has been set.
    var displayName: String?
    
    /// The IP address where this device was last seen. (May be a few minutes out of date, for efficiency reasons).
    var lastSeenIp: String?
    
    /// The timestamp (in milliseconds since the unix epoch) when this devices was last seen. (May be a few minutes out of date, for efficiency reasons).
    var lastSeenTs: UInt64
    
    /// The latest recorded user agent for the device.
    var lastSeenUserAgent: String?
    
    private static let kDeviceIdJSONKey = "device_id"
    private static let kDisplayNameJSONKey = "display_name"
    private static let kLastSeenIPJSONKey = "last_seen_ip"
    private static let kLastSeenTimestampJSONKey = "last_seen_ts"
    private static let kLastSeenUserAgentJSONKey = "org.matrix.msc3852.last_seen_user_agent"
    
    required init?(coder aDecoder: NSCoder) {
        guard let deviceId = aDecoder.decodeObject(forKey: Self.kDeviceIdJSONKey) as? String else {
            return nil
        }
        
        self.deviceId = deviceId
        displayName = aDecoder.decodeObject(forKey: Self.kDisplayNameJSONKey) as? String
        lastSeenIp = aDecoder.decodeObject(forKey: Self.kLastSeenIPJSONKey) as? String
        
        if let lastSeenTsNumber = aDecoder.decodeObject(forKey: Self.kLastSeenTimestampJSONKey) as? NSNumber {
            lastSeenTs = lastSeenTsNumber.uint64Value
        } else {
            lastSeenTs = 0
        }
        
        lastSeenUserAgent = aDecoder.decodeObject(forKey: Self.kLastSeenUserAgentJSONKey) as? String
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}

class MXKAccountData: NSObject, NSCoding {
    /// The account's credentials: homeserver, access token, user id.
    private(set) var mxCredentials: MXCredentials
    
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
    private(set) var threePIDs: [MXThirdPartyIdentifier]?
    
    /// The account user's device.
    /// [self loadDeviceInformation] must be called to update the property.
    private(set) var device: MXDevice?
    
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
    
    // The account's preferred Presence status to share while the application is in foreground.
    // Defaults to MXPresenceOnline.
    // var preferredSyncPresence: MXPresence = .online
    
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
    
    // MARK: - Soft logout
    
    /// Flag to indicate if the account has been logged out by the homeserver admin.
    private(set) var isSoftLogout = false
    
    // MARK: - NSCoding
    
    required init?(coder: NSCoder) {
        let homeServerURL = coder.decodeObject(forKey: "homeserverurl") as? String
        let userId = coder.decodeObject(forKey: "userid") as? String
        let accessToken = coder.decodeObject(forKey: "accesstoken") as? String
        let identityServerURL = coder.decodeObject(forKey: "identityserverurl") as? String
        let identityServerAccessToken = coder.decodeObject(forKey: "identityserveraccesstoken") as? String
        
        mxCredentials = MXCredentials(homeServer: homeServerURL,
                                      userId: userId,
                                      accessToken: accessToken)
        
        mxCredentials.accessTokenExpiresAt = UInt64(coder.decodeInt64(forKey: "accessTokenExpiresAt"))
        mxCredentials.refreshToken = coder.decodeObject(forKey: "refreshToken") as? String
        mxCredentials.identityServer = identityServerURL
        mxCredentials.identityServerAccessToken = identityServerAccessToken
        mxCredentials.deviceId = coder.decodeObject(forKey: "deviceId") as? String
        mxCredentials.allowedCertificate = coder.decodeObject(forKey: "allowedCertificate") as? Data
        
        self.identityServerURL = identityServerURL ?? ""
        
        super.init()
        
        if let threePIDs = coder.decodeObject(forKey: "threePIDs") as? [MXThirdPartyIdentifier] {
            self.threePIDs = threePIDs
        }
        
        if let device = coder.decodeObject(forKey: "device") as? MXDevice {
            self.device = device
        }
        
        if let antivirusServerURL = coder.decodeObject(forKey: "antivirusserverurl") as? String {
            self.antivirusServerURL = antivirusServerURL
        }
        
        if let pushGatewayURL = coder.decodeObject(forKey: "pushgatewayurl") as? String {
            self.pushGatewayURL = pushGatewayURL
        }
        
        hasPusherForPushNotifications = coder.decodeBool(forKey: "_enablePushNotifications")
        hasPusherForPushKitNotifications = coder.decodeBool(forKey: "enablePushKitNotifications")
        enableInAppNotifications = coder.decodeBool(forKey: "enableInAppNotifications")
        
        isDisabled = coder.decodeBool(forKey: "disabled")
        isSoftLogout = coder.decodeBool(forKey: "isSoftLogout")
        
        isWarnedAboutEncryption = coder.decodeBool(forKey: "warnedAboutEncryption")
        
        // if let presenceString = coder.decodeObject(of: NSString.self, forKey: "preferredSyncPresence") as? String {
        //     preferredSyncPresence = MXTools.presence(presenceString)
        // } else {
        //    preferredSyncPresence = .online
        // }
        
        if let others = coder.decodeObject(forKey: "others") as? NSMutableDictionary {
            self.others = others
        }
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not available")
    }
}
