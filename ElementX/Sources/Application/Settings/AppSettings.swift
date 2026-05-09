//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

#if IS_MAIN_APP
import EmbeddedElementCall
#endif

import Foundation
import SwiftUI

/// Common settings between app and NSE
protocol CommonSettingsProtocol: AnyObject {
    var lastNotificationBootTime: TimeInterval? { get set }
    var notificationSoundName: RemotePreference<UNNotificationSoundName> { get }
    
    var logLevel: LogLevel { get }
    var traceLogPacks: Set<TraceLogPack> { get }
    var bugReportRageshakeURL: RemotePreference<RageshakeConfiguration> { get }
    
    var enableOnlySignedDeviceIsolationMode: Bool { get }
    var threadsEnabled: Bool { get }
    var hideQuietNotificationAlerts: Bool { get }
}

enum AppBuildType {
    case debug
    case nightly
    case release
}

/// Store Element specific app settings.
final class AppSettings {
    private enum UserDefaultsKeys: String {
        case lastVersionLaunched
        case seenInvites
        case hasSeenNewSoundBanner
        case appLockNumberOfPINAttempts
        case appLockNumberOfBiometricAttempts
        case timelineStyle
        
        case analyticsConsentState
        case hasRunNotificationPermissionsOnboarding
        case hasRunIdentityConfirmationOnboarding
        case hasRequestedLocationAlwaysLocationAuthorization
        
        case frequentlyUsedSystemEmojis
        
        case pushProvider
        case enableNotifications
        case enableInAppNotifications
        case pusherProfileTag
        case lastNotificationBootTime
        case logLevel
        case traceLogPacks
        case viewSourceEnabled
        case optimizeMediaUploads
        case appAppearance
        case sharePresence
        
        case elementCallBaseURLOverride
        
        case voiceMessagePlaybackSpeed
        
        // Live Location
        case liveLocationSharingTimeoutDatesByRoomID
        case liveLocationMinimumDistanceUpdate
        case liveLocationDisclaimerDisplayed
        
        // Feature flags
        case fuzzyRoomListSearchEnabled
        case lowPriorityFilterEnabled
        case enableOnlySignedDeviceIsolationMode
        case knockingEnabled
        case threadsEnabled
        case roomThreadListEnabled
        case linkPreviewsEnabled
        case focusEventOnNotificationTap
        case linkNewDeviceEnabled
        case automaticBackPaginationEnabled
        
        // Doug's tweaks 🔧
        case roomListActivityVisibility
        case hideQuietNotificationAlerts
        
        case developerOptionsEnabled
    }
    
    private static var suiteName: String = InfoPlistReader.main.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    static var appBuildType: AppBuildType {
        #if DEBUG
        return .debug
        #else
        switch InfoPlistReader.main.baseBundleIdentifier {
        case "org.ucmeet.UCMeetChat.nightly":
            return .nightly
        default:
            return .release
        }
        #endif
    }
    
    static func resetAllSettings() {
        MXLog.warning("Resetting the AppSettings.")
        store.removePersistentDomain(forName: suiteName)
    }
    
    static func resetSessionSpecificSettings() {
        MXLog.warning("Resetting the user session specific AppSettings.")
        store.removeObject(forKey: UserDefaultsKeys.hasRunIdentityConfirmationOnboarding.rawValue)
    }
    
    static func configureWithSuiteName(_ name: String) {
        suiteName = name
        
        guard let userDefaults = UserDefaults(suiteName: name) else {
            fatalError("Fail to load shared UserDefaults")
        }
        
        store = userDefaults
    }
    
    // MARK: - Hooks
    
    // swiftlint:disable:next function_parameter_count
    func override(accountProviders: [String],
                  allowOtherAccountProviders: Bool,
                  hideBrandChrome: Bool,
                  pushGatewayBaseURL: URL,
                  oAuthRedirectURL: URL,
                  websiteURL: URL,
                  logoURL: URL,
                  copyrightURL: URL,
                  acceptableUseURL: URL,
                  privacyURL: URL,
                  encryptionURL: URL,
                  deviceVerificationURL: URL,
                  chatBackupDetailsURL: URL,
                  identityPinningViolationDetailsURL: URL,
                  historySharingDetailsURL: URL,
                  elementWebHosts: [String],
                  accountProvisioningHost: String,
                  bugReportApplicationID: String,
                  analyticsTermsURL: URL?,
                  mapTilerConfiguration: MapTilerConfiguration) {
        self.accountProviders = accountProviders
        self.allowOtherAccountProviders = allowOtherAccountProviders
        self.hideBrandChrome = hideBrandChrome
        self.pushGatewayBaseURL = pushGatewayBaseURL
        self.oAuthRedirectURL = oAuthRedirectURL
        self.websiteURL = websiteURL
        self.logoURL = logoURL
        self.copyrightURL = copyrightURL
        self.acceptableUseURL = acceptableUseURL
        self.privacyURL = privacyURL
        self.encryptionURL = encryptionURL
        self.deviceVerificationURL = deviceVerificationURL
        self.chatBackupDetailsURL = chatBackupDetailsURL
        self.identityPinningViolationDetailsURL = identityPinningViolationDetailsURL
        self.historySharingDetailsURL = historySharingDetailsURL
        self.elementWebHosts = elementWebHosts
        self.accountProvisioningHost = accountProvisioningHost
        self.bugReportApplicationID = bugReportApplicationID
        self.analyticsTermsURL = analyticsTermsURL
        self.mapTilerConfiguration = mapTilerConfiguration
    }
    
    // MARK: - Application
    
    /// The last known version of the app that was launched on this device, which is
    /// used to detect when migrations should be run. When `nil` the app may have been
    /// deleted between runs so should clear data in the shared container and keychain.
    @UserPreference(key: UserDefaultsKeys.lastVersionLaunched, storageType: .userDefaults(store))
    var lastVersionLaunched: String?
        
    /// The Set of room identifiers of invites that the user already saw in the invites list.
    /// This Set is being used to implement badges for unread invites.
    @UserPreference(key: UserDefaultsKeys.seenInvites, defaultValue: [], storageType: .userDefaults(store))
    var seenInvites: Set<String>
    
    /// Defaults to `true` for new users, and we use a migration to set it to `false` for existing users.
    @UserPreference(key: UserDefaultsKeys.hasSeenNewSoundBanner, defaultValue: true, storageType: .userDefaults(store))
    var hasSeenNewSoundBanner
    
    /// The initial set of account providers shown to the user in the authentication flow.
    ///
    /// Account provider is the friendly term for the server name. It should not contain an `https` prefix and should
    /// match the last part of the user ID. For example `example.com` and not `https://matrix.example.com`.
    // UCMeet: customer's homeserver domain (matches user ID suffix @user:matrix.ucmeet.org)
    private(set) var accountProviders = ["matrix.ucmeet.org"]
    /// Whether or not the user is allowed to manually enter their own account provider or must select from one of `defaultAccountProviders`.
    private(set) var allowOtherAccountProviders = true
    /// Whether the components surrounding the app brand/logo should be hidden or not
    private(set) var hideBrandChrome = false
    
    /// The task identifier used for background app refresh. Also used in main target's the Info.plist
    let backgroundAppRefreshTaskIdentifier = "org.ucmeet.UCMeetChat.background.refresh"

    /// A URL where users can go read more about the app.
    private(set) var websiteURL: URL = "https://www.ucmeet.info"
    /// A URL that contains the app's logo that may be used when showing content in a web view.
    private(set) var logoURL: URL = "https://www.ucmeet.info/mobile-icon.png" // TODO: UCMeet — provide real logo URL
    /// A URL that contains that app's copyright notice.
    private(set) var copyrightURL: URL = "https://www.ucmeet.info/privacy-security"
    /// A URL that contains the app's Terms of use.
    private(set) var acceptableUseURL: URL = "https://www.ucmeet.info/ucmeetchat-terms-of-use"
    /// A URL that contains the app's Privacy Policy.
    private(set) var privacyURL: URL = "https://www.ucmeet.info/privacy-security"
    /// A URL where users can go read more about encryption in general.
    private(set) var encryptionURL: URL = "https://www.ucmeet.info/privacy-security"
    /// A URL where users can go read more about device verification..
    private(set) var deviceVerificationURL: URL = "https://www.ucmeet.info/support"
    /// A URL where users can go read more about the chat backup.
    private(set) var chatBackupDetailsURL: URL = "https://www.ucmeet.info/support"
    /// A URL where users can go read more about identity pinning violations
    private(set) var identityPinningViolationDetailsURL: URL = "https://www.ucmeet.info/support"
    /// A URL describing how history sharing works
    private(set) var historySharingDetailsURL: URL = "https://www.ucmeet.info/support"

    /// Any domains that the web app may be hosted on - used for handling links.
    private(set) var elementWebHosts: [String] = [] // UCMeet: no web client hosted
    /// The domain that account provisioning links will be hosted on - used for handling the links.
    private(set) var accountProvisioningHost = "" // UCMeet: no account provisioning
    /// The App Store URL for Element Pro, shown to the user when a homeserver requires that app.
    /// **Note:** This property isn't overridable as it in unexpected for forks to come across the error (or to even have a "Pro" app).
    let elementProAppStoreURL: URL = "https://apps.apple.com/app/element-pro-for-work/id6502951615"
    
    @UserPreference(key: UserDefaultsKeys.appAppearance, defaultValue: .system, storageType: .userDefaults(store))
    var appAppearance: AppAppearance
    
    // MARK: - Security
    
    /// The app must be locked with a PIN code as part of the authentication flow.
    let appLockIsMandatory = false
    /// The amount of time the app can remain in the background for without requesting the PIN/TouchID/FaceID.
    let appLockGracePeriod: TimeInterval = 0
    /// Any codes that the user isn't allowed to use for their PIN.
    let appLockPINCodeBlockList = ["0000", "1234"]
    /// The number of attempts the user has made to unlock the app with a PIN code (resets when unlocked).
    @UserPreference(key: UserDefaultsKeys.appLockNumberOfPINAttempts, defaultValue: 0, storageType: .userDefaults(store))
    var appLockNumberOfPINAttempts: Int
    
    // MARK: - Authentication
    
    /// Any pre-defined static client registrations for OAuth issuers.
    let oAuthStaticRegistrations: [URL: String] = ["https://id.thirdroom.io/realms/thirdroom": "elementx"]
    /// The redirect URL used for OAuth. UCMeet uses a custom URL scheme with SINGLE slash (no authority).
    /// MAS native-app policy requires: no `://`, scheme matches client_uri in reverse-DNS.
    /// `org.ucmeet.UCMeetChat:/callback` → matches `www.ucmeet.info`.
    /// We retain the custom-scheme approach instead of upstream's `https://element.io/oauth/ios/...`
    /// Universal Link approach because we don't host an AASA at our website yet.
    private(set) var oAuthRedirectURL: URL! = URL(string: "org.ucmeet.UCMeetChat:/callback")

    private(set) lazy var oAuthConfiguration = OAuthConfiguration(clientName: InfoPlistReader.main.bundleDisplayName,
                                                                  redirectURI: oAuthRedirectURL,
                                                                  clientURI: websiteURL,
                                                                  logoURI: logoURL,
                                                                  tosURI: acceptableUseURL,
                                                                  policyURI: privacyURL,
                                                                  staticRegistrations: oAuthStaticRegistrations.mapKeys { $0.absoluteString })
    
    /// Whether or not the Create Account button is shown on the start screen.
    ///
    /// **Note:** Setting this to false doesn't prevent someone from creating an account when the selected homeserver's MAS allows registration.
    let showCreateAccountButton = true
    
    // MARK: - Notifications

    /// The push notification provider to use for delivering remote notifications.
    /// `.apns` sends APNs device token directly to Sygnal (type: apns). `.firebase` routes through FCM (type: gcm).
    /// UCMeet uses `.apns` because Sygnal's GCM pushkin doesn't support APNs-format payloads in FCM v1 data messages.
    @UserPreference(key: UserDefaultsKeys.pushProvider, defaultValue: PushProvider.apns, storageType: .userDefaults(store))
    var pushProvider: PushProvider

    var pusherAppID: String {
        #if DEBUG
        InfoPlistReader.main.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.main.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    private(set) var pushGatewayBaseURL: URL = "https://push.ucmeet.org"
    var pushGatewayNotifyEndpoint: URL {
        pushGatewayBaseURL.appending(path: "_matrix/push/v1/notify")
    }
    
    @UserPreference(key: UserDefaultsKeys.enableNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableNotifications

    @UserPreference(key: UserDefaultsKeys.enableInAppNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableInAppNotifications
    
    @UserPreference(key: UserDefaultsKeys.hideQuietNotificationAlerts, defaultValue: false, storageType: .userDefaults(store))
    var hideQuietNotificationAlerts

    /// Tag describing which set of device specific rules a pusher executes.
    @UserPreference(key: UserDefaultsKeys.pusherProfileTag, storageType: .userDefaults(store))
    var pusherProfileTag: String?
    
    /// The device's last boot time as recorded by the NSE.
    @UserPreference(key: UserDefaultsKeys.lastNotificationBootTime, storageType: .userDefaults(store))
    var lastNotificationBootTime: TimeInterval?
    
    /// The name of sound played when delivering noisy notifications.
    var notificationSoundName: RemotePreference<UNNotificationSoundName> = .init(.init("message.caf"))
    
    // MARK: - Logging
        
    @UserPreference(key: UserDefaultsKeys.logLevel, defaultValue: LogLevel.info, storageType: .userDefaults(store))
    var logLevel
    
    @UserPreference(key: UserDefaultsKeys.traceLogPacks, defaultValue: [], storageType: .userDefaults(store))
    var traceLogPacks: Set<TraceLogPack>
    
    // MARK: - Bug report
    
    let bugReportRageshakeURL: RemotePreference<RageshakeConfiguration> = .init(Secrets.rageshakeURL.map { .url(URL(string: $0)!) } ?? .disabled) // swiftlint:disable:this force_unwrapping
    let bugReportSentryURL: URL? = Secrets.sentryDSN.map { URL(string: $0)! } // swiftlint:disable:this force_unwrapping
    let bugReportSentryRustURL: URL? = Secrets.sentryRustDSN.map { URL(string: $0)! } // swiftlint:disable:this force_unwrapping
    /// The name allocated by the bug report server
    private(set) var bugReportApplicationID = "ucmeet-ios" // TODO: UCMeet — confirm app ID for bug reports
    
    // MARK: - Analytics
    
    /// The configuration to use for analytics. Set to `nil` to disable analytics.
    let analyticsConfiguration: AnalyticsConfiguration? = AppSettings.makeAnalyticsConfiguration()
    /// The URL to open with more information about analytics terms. When this is `nil` the "Learn more" link will be hidden.
    // UCMeet: analytics disabled, no cookie policy needed
    private(set) var analyticsTermsURL: URL?
    /// Whether or not there the app is able ask for user consent to enable analytics or sentry reporting.
    var canPromptForAnalytics: Bool {
        analyticsConfiguration != nil || bugReportSentryURL != nil
    }
    
    private static func makeAnalyticsConfiguration() -> AnalyticsConfiguration? {
        guard let host = Secrets.postHogHost, let apiKey = Secrets.postHogAPIKey else { return nil }
        return AnalyticsConfiguration(host: host, apiKey: apiKey)
    }
    
    /// Whether the user has opted in to send analytics.
    @UserPreference(key: UserDefaultsKeys.analyticsConsentState, defaultValue: AnalyticsConsentState.unknown, storageType: .userDefaults(store))
    var analyticsConsentState
    
    @UserPreference(key: UserDefaultsKeys.hasRunNotificationPermissionsOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunNotificationPermissionsOnboarding
    
    @UserPreference(key: UserDefaultsKeys.hasRunIdentityConfirmationOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunIdentityConfirmationOnboarding
    
    @UserPreference(key: UserDefaultsKeys.hasRequestedLocationAlwaysLocationAuthorization, defaultValue: false, storageType: .userDefaults(store))
    var hasRequestedLocationAlwaysLocationAuthorization
    
    @UserPreference(key: UserDefaultsKeys.frequentlyUsedSystemEmojis, defaultValue: [FrequentlyUsedEmoji](), storageType: .userDefaults(store))
    var frequentlyUsedSystemEmojis
    
    // MARK: - Live Location
    
    @UserPreference(key: UserDefaultsKeys.liveLocationSharingTimeoutDatesByRoomID, defaultValue: [String: LiveLocationSession](), storageType: .userDefaults(store))
    var liveLocationSharingSessionsByRoomID
    
    @UserPreference(key: UserDefaultsKeys.liveLocationMinimumDistanceUpdate, defaultValue: 10, storageType: .userDefaults(store))
    var liveLocationMinimumDistanceUpdate
    
    @UserPreference(key: UserDefaultsKeys.liveLocationDisclaimerDisplayed, defaultValue: false, storageType: .userDefaults(store))
    var liveLocationDisclaimerDisplayed
    
    // MARK: - Home Screen
    
    @UserPreference(key: UserDefaultsKeys.roomListActivityVisibility, defaultValue: .current, storageType: .userDefaults(store))
    var roomListActivityVisibility: RoomListActivityVisibility
    
    // MARK: - Room Screen
    
    @UserPreference(key: UserDefaultsKeys.viewSourceEnabled, defaultValue: appBuildType == .debug, storageType: .userDefaults(store))
    var viewSourceEnabled
    
    @UserPreference(key: UserDefaultsKeys.optimizeMediaUploads, defaultValue: true, storageType: .userDefaults(store))
    var optimizeMediaUploads

    @UserPreference(key: UserDefaultsKeys.voiceMessagePlaybackSpeed, defaultValue: AudioPlaybackSpeed.default, storageType: .userDefaults(store))
    var voiceMessagePlaybackSpeed: AudioPlaybackSpeed

    /// Whether or not to show a warning on the media caption composer so the user knows
    /// that captions might not be visible to users who are using other Matrix clients.
    let shouldShowMediaCaptionWarning = true

    // MARK: - Element Call
    
    #if IS_MAIN_APP
    // swiftlint:disable:next force_unwrapping
    let elementCallBaseURL: URL = EmbeddedElementCall.appURL!
    #endif
    
    // UCMeet: Element Call analytics disabled — no data sent to Element's PostHog/Sentry
    let elementCallPosthogAPIHost = ""
    let elementCallPosthogAPIKey = ""
    let elementCallPosthogSentryDSN = ""
    
    @UserPreference(key: UserDefaultsKeys.elementCallBaseURLOverride, defaultValue: nil, storageType: .userDefaults(store))
    var elementCallBaseURLOverride: URL?
    
    // MARK: - Users
    
    /// Whether to hide the display name and avatar of ignored users as these may contain objectionable content.
    let hideIgnoredUserProfiles = true
    
    // MARK: - Maps
    
    /// maptiler base url
    private(set) var mapTilerConfiguration = MapTilerConfiguration(baseURL: "https://api.maptiler.com/maps",
                                                                   apiKey: Secrets.mapLibreAPIKey,
                                                                   lightStyleID: "basic-v2",
                                                                   darkStyleID: "basic-v2-dark")
    
    // MARK: - Presence
    
    @UserPreference(key: UserDefaultsKeys.sharePresence, defaultValue: true, storageType: .userDefaults(store))
    var sharePresence
    
    // MARK: - Feature Flags
    
    /// Others
    @UserPreference(key: UserDefaultsKeys.fuzzyRoomListSearchEnabled, defaultValue: false, storageType: .userDefaults(store))
    var fuzzyRoomListSearchEnabled
    
    @UserPreference(key: UserDefaultsKeys.lowPriorityFilterEnabled, defaultValue: false, storageType: .userDefaults(store))
    var lowPriorityFilterEnabled
    
    /// Configuration to enable only signed device isolation mode for  crypto. In this mode only devices signed by their owner will be considered in e2ee rooms.
    @UserPreference(key: UserDefaultsKeys.enableOnlySignedDeviceIsolationMode, defaultValue: false, storageType: .userDefaults(store))
    var enableOnlySignedDeviceIsolationMode
    
    @UserPreference(key: UserDefaultsKeys.knockingEnabled, defaultValue: false, storageType: .userDefaults(store))
    var knockingEnabled
    
    @UserPreference(key: UserDefaultsKeys.threadsEnabled, defaultValue: false, storageType: .userDefaults(store))
    var threadsEnabled
    
    @UserPreference(key: UserDefaultsKeys.roomThreadListEnabled, defaultValue: false, storageType: .userDefaults(store))
    var roomThreadListEnabled
    
    @UserPreference(key: UserDefaultsKeys.focusEventOnNotificationTap, defaultValue: false, storageType: .userDefaults(store))
    var focusEventOnNotificationTap
        
    @UserPreference(key: UserDefaultsKeys.linkPreviewsEnabled, defaultValue: false, storageType: .userDefaults(store))
    var linkPreviewsEnabled
    
    @UserPreference(key: UserDefaultsKeys.linkNewDeviceEnabled, defaultValue: false, storageType: .userDefaults(store))
    var linkNewDeviceEnabled
    
    @UserPreference(key: UserDefaultsKeys.automaticBackPaginationEnabled, defaultValue: false, storageType: .userDefaults(store))
    var automaticBackPaginationEnabled
    
    @UserPreference(key: UserDefaultsKeys.developerOptionsEnabled, defaultValue: appBuildType != .release, storageType: .userDefaults(store))
    var developerOptionsEnabled
}

extension AppSettings: CommonSettingsProtocol { }
