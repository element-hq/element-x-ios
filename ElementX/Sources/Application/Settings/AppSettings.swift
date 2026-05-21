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
protocol CommonSettingsProtocol: AnyObject, Sendable {
    var lastNotificationBootTime: TimeInterval? { get set }
    var selectedNotificationTone: NotificationTone? { get set }

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
///
/// State is persisted in `UserDefaults`, which is thread-safe per Apple's documentation, hence `@unchecked`.
final class AppSettings: @unchecked Sendable {
    fileprivate enum UserDefaultsKeys: String, PreferenceKeyable {
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
        
        case enableNotifications
        case enableInAppNotifications
        case pusherProfileTag
        case lastNotificationBootTime
        case selectedNotificationTone
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
        case jumpToReadMarkerEnabled
        case focusEventOnNotificationTap
        case linkNewDeviceEnabled
        case automaticBackPaginationEnabled
        case clientPausingAndResumingEnabled
        
        // Doug's tweaks 🔧
        case roomListActivityVisibility
        case hideQuietNotificationAlerts
        
        case developerOptionsEnabled
    }
    
    static let suiteName: String = InfoPlistReader.main.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private let store: UserDefaultsProtocol
    
    static var appBuildType: AppBuildType {
        #if DEBUG
        return .debug
        #else
        switch InfoPlistReader.main.baseBundleIdentifier {
        case "io.element.elementx.nightly":
            return .nightly
        default:
            return .release
        }
        #endif
    }
    
    func resetAllSettings() {
        MXLog.warning("Resetting the AppSettings.")
        store.reset()
    }
    
    func resetSessionSpecificSettings() {
        MXLog.warning("Resetting the user session specific AppSettings.")
        store.removeObject(forKey: UserDefaultsKeys.hasRunIdentityConfirmationOnboarding.rawValue)
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
    @UserPreference
    var lastVersionLaunched: String?
        
    /// The Set of room identifiers of invites that the user already saw in the invites list.
    /// This Set is being used to implement badges for unread invites.
    @UserPreference
    var seenInvites: Set<String>
    
    /// Defaults to `true` for new users, and we use a migration to set it to `false` for existing users.
    @UserPreference
    var hasSeenNewSoundBanner: Bool
    
    /// The initial set of account providers shown to the user in the authentication flow.
    ///
    /// Account provider is the friendly term for the server name. It should not contain an `https` prefix and should
    /// match the last part of the user ID. For example `example.com` and not `https://matrix.example.com`.
    private(set) var accountProviders = ["matrix.org"]
    /// Whether or not the user is allowed to manually enter their own account provider or must select from one of `defaultAccountProviders`.
    private(set) var allowOtherAccountProviders = true
    /// Whether the components surrounding the app brand/logo should be hidden or not
    private(set) var hideBrandChrome = false
    
    /// The task identifier used for background app refresh. Also used in main target's the Info.plist
    let backgroundAppRefreshTaskIdentifier = "io.element.elementx.background.refresh"

    /// A URL where users can go read more about the app.
    private(set) var websiteURL: URL = "https://element.io"
    /// A URL that contains the app's logo that may be used when showing content in a web view.
    private(set) var logoURL: URL = "https://element.io/mobile-icon.png"
    /// A URL that contains that app's copyright notice.
    private(set) var copyrightURL: URL = "https://element.io/copyright"
    /// A URL that contains the app's Terms of use.
    private(set) var acceptableUseURL: URL = "https://element.io/acceptable-use-policy-terms"
    /// A URL that contains the app's Privacy Policy.
    private(set) var privacyURL: URL = "https://element.io/privacy"
    /// A URL where users can go read more about encryption in general.
    private(set) var encryptionURL: URL = "https://element.io/help#encryption"
    /// A URL where users can go read more about device verification..
    private(set) var deviceVerificationURL: URL = "https://element.io/help#encryption-device-verification"
    /// A URL where users can go read more about the chat backup.
    private(set) var chatBackupDetailsURL: URL = "https://element.io/help#encryption5"
    /// A URL where users can go read more about identity pinning violations
    private(set) var identityPinningViolationDetailsURL: URL = "https://element.io/help#encryption18"
    /// A URL describing how history sharing works
    private(set) var historySharingDetailsURL: URL = "https://element.io/en/help#e2ee-history-sharing"

    /// Any domains that Element web may be hosted on - used for handling links.
    private(set) var elementWebHosts = ["app.element.io", "staging.element.io", "develop.element.io"]
    /// The domain that account provisioning links will be hosted on - used for handling the links.
    private(set) var accountProvisioningHost = "mobile.element.io"
    /// The App Store URL for Element Pro, shown to the user when a homeserver requires that app.
    /// **Note:** This property isn't overridable as it in unexpected for forks to come across the error (or to even have a "Pro" app).
    let elementProAppStoreURL: URL = "https://apps.apple.com/app/element-pro-for-work/id6502951615"
    
    @UserPreference
    var appAppearance: AppAppearance
    
    // MARK: - Security
    
    /// The app must be locked with a PIN code as part of the authentication flow.
    let appLockIsMandatory = false
    /// The amount of time the app can remain in the background for without requesting the PIN/TouchID/FaceID.
    let appLockGracePeriod: TimeInterval = 0
    /// Any codes that the user isn't allowed to use for their PIN.
    let appLockPINCodeBlockList = ["0000", "1234"]
    /// The number of attempts the user has made to unlock the app with a PIN code (resets when unlocked).
    @UserPreference
    var appLockNumberOfPINAttempts: Int
    
    // MARK: - Authentication
    
    /// Any pre-defined static client registrations for OAuth issuers.
    let oAuthStaticRegistrations: [URL: String] = ["https://id.thirdroom.io/realms/thirdroom": "elementx"]
    /// The redirect URL used for OAuth. For the normal case we don't actually need the bundle ID as the web authentication session handles the redirect internally.
    /// However in the case where MAS sends the user to an external app, we need to make sure that the system will open the correct variant of the app (e.g. Nightly).
    private(set) var oAuthRedirectURL: URL! = URL(string: "https://element.io/oauth/ios/\(InfoPlistReader.main.bundleIdentifier)")
    
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
    
    var pusherAppID: String {
        #if DEBUG
        InfoPlistReader.main.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.main.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    private(set) var pushGatewayBaseURL: URL = "https://matrix.org"
    var pushGatewayNotifyEndpoint: URL {
        pushGatewayBaseURL.appending(path: "_matrix/push/v1/notify")
    }
    
    @UserPreference
    var enableNotifications: Bool

    @UserPreference
    var enableInAppNotifications: Bool
    
    @UserPreference
    var hideQuietNotificationAlerts: Bool

    /// Tag describing which set of device specific rules a pusher executes.
    @UserPreference
    var pusherProfileTag: String?
    
    /// The device's last boot time as recorded by the NSE.
    @UserPreference
    var lastNotificationBootTime: TimeInterval?

    /// The sound played when delivering noisy notifications. If nil, use the ElementX default
    @UserPreference
    var selectedNotificationTone: NotificationTone?

    // MARK: - Logging
        
    @UserPreference
    var logLevel: LogLevel
    
    @UserPreference
    var traceLogPacks: Set<TraceLogPack>
    
    // MARK: - Bug report
    
    let bugReportRageshakeURL: RemotePreference<RageshakeConfiguration> = .init(Secrets.rageshakeURL.map { .url(URL(string: $0)!) } ?? .disabled) // swiftlint:disable:this force_unwrapping
    let bugReportSentryURL: URL? = Secrets.sentryDSN.map { URL(string: $0)! } // swiftlint:disable:this force_unwrapping
    let bugReportSentryRustURL: URL? = Secrets.sentryRustDSN.map { URL(string: $0)! } // swiftlint:disable:this force_unwrapping
    /// The name allocated by the bug report server
    private(set) var bugReportApplicationID = "element-x-ios"
    
    // MARK: - Analytics
    
    /// The configuration to use for analytics. Set to `nil` to disable analytics.
    let analyticsConfiguration: AnalyticsConfiguration? = AppSettings.makeAnalyticsConfiguration()
    /// The URL to open with more information about analytics terms. When this is `nil` the "Learn more" link will be hidden.
    private(set) var analyticsTermsURL: URL? = "https://element.io/cookie-policy"
    /// Whether or not there the app is able ask for user consent to enable analytics or sentry reporting.
    var canPromptForAnalytics: Bool {
        analyticsConfiguration != nil || bugReportSentryURL != nil
    }
    
    private static func makeAnalyticsConfiguration() -> AnalyticsConfiguration? {
        guard let host = Secrets.postHogHost, let apiKey = Secrets.postHogAPIKey else { return nil }
        return AnalyticsConfiguration(host: host, apiKey: apiKey)
    }
    
    /// Whether the user has opted in to send analytics.
    @UserPreference
    var analyticsConsentState: AnalyticsConsentState
    
    @UserPreference
    var hasRunNotificationPermissionsOnboarding: Bool
    
    @UserPreference
    var hasRunIdentityConfirmationOnboarding: Bool
    
    @UserPreference
    var hasRequestedLocationAlwaysLocationAuthorization: Bool
    
    @UserPreference
    var frequentlyUsedSystemEmojis: [FrequentlyUsedEmoji]
    
    // MARK: - Live Location
    
    @UserPreference
    var liveLocationSharingSessionsByRoomID: [String: LiveLocationSession]
    
    @UserPreference
    var liveLocationMinimumDistanceUpdate: Int
    
    @UserPreference
    var liveLocationDisclaimerDisplayed: Bool
    
    // MARK: - Home Screen
    
    @UserPreference
    var roomListActivityVisibility: RoomListActivityVisibility
    
    // MARK: - Room Screen
    
    @UserPreference
    var viewSourceEnabled: Bool
    
    @UserPreference
    var optimizeMediaUploads: Bool

    @UserPreference
    var voiceMessagePlaybackSpeed: AudioPlaybackSpeed

    /// Whether or not to show a warning on the media caption composer so the user knows
    /// that captions might not be visible to users who are using other Matrix clients.
    let shouldShowMediaCaptionWarning = true

    // MARK: - Element Call
    
    #if IS_MAIN_APP
    // swiftlint:disable:next force_unwrapping
    let elementCallBaseURL: URL = EmbeddedElementCall.appURL!
    #endif
    
    // These are publicly availble on https://call.element.io so we don't neeed to treat them as secrets
    let elementCallPosthogAPIHost = "https://posthog-element-call.element.io"
    let elementCallPosthogAPIKey = "phc_rXGHx9vDmyEvyRxPziYtdVIv0ahEv8A9uLWFcCi1WcU"
    let elementCallPosthogSentryDSN = "https://3bd2f95ba5554d4497da7153b552ffb5@sentry.tools.element.io/41"
    
    @UserPreference
    var elementCallBaseURLOverride: URL?
    
    // MARK: - Users
    
    /// Whether to hide the display name and avatar of ignored users as these may contain objectionable content.
    let hideIgnoredUserProfiles = true
    
    // MARK: - Maps
    
    /// maptiler base url
    private(set) var mapTilerConfiguration = MapTilerConfiguration(baseURL: "https://api.maptiler.com/maps",
                                                                   apiKey: Secrets.mapLibreAPIKey,
                                                                   lightStyleID: "9bc819c8-e627-474a-a348-ec144fe3d810",
                                                                   darkStyleID: "dea61faf-292b-4774-9660-58fcef89a7f3")
    
    // MARK: - Presence
    
    @UserPreference
    var sharePresence: Bool
    
    // MARK: - Feature Flags
    
    /// Others
    @UserPreference
    var fuzzyRoomListSearchEnabled: Bool
    
    @UserPreference
    var lowPriorityFilterEnabled: Bool
    
    /// Configuration to enable only signed device isolation mode for  crypto. In this mode only devices signed by their owner will be considered in e2ee rooms.
    @UserPreference
    var enableOnlySignedDeviceIsolationMode: Bool
    
    @UserPreference
    var knockingEnabled: Bool
    
    @UserPreference
    var threadsEnabled: Bool
    
    @UserPreference
    var roomThreadListEnabled: Bool
    
    @UserPreference
    var focusEventOnNotificationTap: Bool
        
    @UserPreference
    var linkPreviewsEnabled: Bool
    
    @UserPreference
    var jumpToReadMarkerEnabled: Bool

    @UserPreference
    var linkNewDeviceEnabled: Bool
    
    @UserPreference
    var automaticBackPaginationEnabled: Bool
    
    @UserPreference
    var clientPausingAndResumingEnabled: Bool
    
    @UserPreference
    var developerOptionsEnabled: Bool
	
    init(store: UserDefaultsProtocol) {
        // UserDefaults to be used on reads and writes.
        self.store = store
		
        _lastVersionLaunched = UserPreference(key: .lastVersionLaunched, storage: store)
        _seenInvites = UserPreference(key: .seenInvites, defaultValue: [], storage: store)
        _hasSeenNewSoundBanner = UserPreference(key: .hasSeenNewSoundBanner, defaultValue: true, storage: store)
        _appAppearance = UserPreference(key: .appAppearance, defaultValue: .system, storage: store)
        _appLockNumberOfPINAttempts = UserPreference(key: .appLockNumberOfPINAttempts, defaultValue: 0, storage: store)
        _enableNotifications = UserPreference(key: .enableNotifications, defaultValue: true, storage: store)
        _enableInAppNotifications = UserPreference(key: .enableInAppNotifications, defaultValue: true, storage: store)
        _hideQuietNotificationAlerts = UserPreference(key: .hideQuietNotificationAlerts, defaultValue: false, storage: store)
        _pusherProfileTag = UserPreference(key: .pusherProfileTag, storage: store)
        _lastNotificationBootTime = UserPreference(key: .lastNotificationBootTime, storage: store)
        _selectedNotificationTone = UserPreference(key: .selectedNotificationTone, storage: store)
        _logLevel = UserPreference(key: .logLevel, defaultValue: LogLevel.info, storage: store)
        _traceLogPacks = UserPreference(key: .traceLogPacks, defaultValue: [], storage: store)
        _analyticsConsentState = UserPreference(key: .analyticsConsentState, defaultValue: AnalyticsConsentState.unknown, storage: store)
        _hasRunNotificationPermissionsOnboarding = UserPreference(key: .hasRunNotificationPermissionsOnboarding, defaultValue: false, storage: store)
        _hasRunIdentityConfirmationOnboarding = UserPreference(key: .hasRunIdentityConfirmationOnboarding, defaultValue: false, storage: store)
        _hasRequestedLocationAlwaysLocationAuthorization = UserPreference(key: .hasRequestedLocationAlwaysLocationAuthorization, defaultValue: false, storage: store)
        _frequentlyUsedSystemEmojis = UserPreference(key: .frequentlyUsedSystemEmojis, defaultValue: [FrequentlyUsedEmoji](), storage: store)
        _liveLocationSharingSessionsByRoomID = UserPreference(key: .liveLocationSharingTimeoutDatesByRoomID, defaultValue: [String: LiveLocationSession](), storage: store)
        _liveLocationMinimumDistanceUpdate = UserPreference(key: .liveLocationMinimumDistanceUpdate, defaultValue: 10, storage: store)
        _liveLocationDisclaimerDisplayed = UserPreference(key: .liveLocationDisclaimerDisplayed, defaultValue: false, storage: store)
        _roomListActivityVisibility = UserPreference(key: .roomListActivityVisibility, defaultValue: .current, storage: store)
        _viewSourceEnabled = UserPreference(key: .viewSourceEnabled, defaultValue: Self.appBuildType == .debug, storage: store)
        _optimizeMediaUploads = UserPreference(key: .optimizeMediaUploads, defaultValue: true, storage: store)
        _voiceMessagePlaybackSpeed = UserPreference(key: .voiceMessagePlaybackSpeed, defaultValue: AudioPlaybackSpeed.default, storage: store)
        _elementCallBaseURLOverride = UserPreference(key: .elementCallBaseURLOverride, defaultValue: nil, storage: store)
        _sharePresence = UserPreference(key: .sharePresence, defaultValue: true, storage: store)
        _fuzzyRoomListSearchEnabled = UserPreference(key: .fuzzyRoomListSearchEnabled, defaultValue: false, storage: store)
        _lowPriorityFilterEnabled = UserPreference(key: .lowPriorityFilterEnabled, defaultValue: false, storage: store)
        _enableOnlySignedDeviceIsolationMode = UserPreference(key: .enableOnlySignedDeviceIsolationMode, defaultValue: false, storage: store)
        _knockingEnabled = UserPreference(key: .knockingEnabled, defaultValue: false, storage: store)
        _threadsEnabled = UserPreference(key: .threadsEnabled, defaultValue: false, storage: store)
        _roomThreadListEnabled = UserPreference(key: .roomThreadListEnabled, defaultValue: false, storage: store)
        _focusEventOnNotificationTap = UserPreference(key: .focusEventOnNotificationTap, defaultValue: false, storage: store)
        _linkPreviewsEnabled = UserPreference(key: .linkPreviewsEnabled, defaultValue: false, storage: store)
        _jumpToReadMarkerEnabled = UserPreference(key: .jumpToReadMarkerEnabled, defaultValue: false, storage: store)
        _linkNewDeviceEnabled = UserPreference(key: .linkNewDeviceEnabled, defaultValue: false, storage: store)
        _automaticBackPaginationEnabled = UserPreference(key: .automaticBackPaginationEnabled, defaultValue: false, storage: store)
        _clientPausingAndResumingEnabled = UserPreference(key: .clientPausingAndResumingEnabled, defaultValue: Self.appBuildType != .release, storage: VolatileUserDefaults())
        _developerOptionsEnabled = UserPreference(key: .developerOptionsEnabled, defaultValue: Self.appBuildType != .release, storage: store)
    }
    
    static func volatile() -> AppSettings {
        AppSettings(store: VolatileUserDefaults())
    }
}

extension AppSettings: CommonSettingsProtocol { }

private extension UserPreference {
    convenience init(key: AppSettings.UserDefaultsKeys, defaultValue: T, storage backingStorage: UserDefaultsProtocol, mode: Mode = .localOverRemote) {
        self.init(key: key as any PreferenceKeyable, defaultValue: defaultValue, storage: backingStorage, mode: mode)
    }
    
    convenience init(key: AppSettings.UserDefaultsKeys, storage: UserDefaultsProtocol, mode: Mode = .localOverRemote) where T: ExpressibleByNilLiteral {
        self.init(key: key as any PreferenceKeyable, defaultValue: nil, storage: storage, mode: mode)
    }
}
