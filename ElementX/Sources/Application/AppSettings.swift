//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

// Common settings between app and NSE
protocol CommonSettingsProtocol {
    var logLevel: TracingConfiguration.LogLevel { get }
    var invisibleCryptoEnabled: Bool { get }
}

/// Store Element specific app settings.
final class AppSettings {
    private enum UserDefaultsKeys: String {
        case lastVersionLaunched
        case appLockNumberOfPINAttempts
        case appLockNumberOfBiometricAttempts
        case timelineStyle
        
        case analyticsConsentState
        case hasRunNotificationPermissionsOnboarding
        case hasRunIdentityConfirmationOnboarding
        
        case enableNotifications
        case enableInAppNotifications
        case pusherProfileTag
        case logLevel
        case viewSourceEnabled
        case appAppearance
        case sharePresence
        case hideUnreadMessagesBadge
        
        case elementCallBaseURLOverride
        case elementCallEncryptionEnabled
        
        // Feature flags
        case slidingSyncDiscovery
        case publicSearchEnabled
        case fuzzyRoomListSearchEnabled
        case pinningEnabled
        case invisibleCryptoEnabled
    }
    
    private static var suiteName: String = InfoPlistReader.main.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    #if IS_MAIN_APP
        
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
    
    func override(defaultHomeserverAddress: String? = nil) {
        if let defaultHomeserverAddress {
            self.defaultHomeserverAddress = defaultHomeserverAddress
        }
    }
    
    // MARK: - Application
    
    /// Whether or not the app is a development build that isn't in production.
    static var isDevelopmentBuild: Bool = {
        #if DEBUG
        true
        #else
        let apps = ["io.element.elementx.nightly", "io.element.elementx.pr"]
        return apps.contains(InfoPlistReader.main.baseBundleIdentifier)
        #endif
    }()
    
    /// The last known version of the app that was launched on this device, which is
    /// used to detect when migrations should be run. When `nil` the app may have been
    /// deleted between runs so should clear data in the shared container and keychain.
    @UserPreference(key: UserDefaultsKeys.lastVersionLaunched, storageType: .userDefaults(store))
    var lastVersionLaunched: String?
        
    /// The default homeserver address used. This is intentionally a string without a scheme
    /// so that it can be passed to Rust as a ServerName for well-known discovery.
    private(set) var defaultHomeserverAddress = "matrix.org"
    
    /// The task identifier used for background app refresh. Also used in main target's the Info.plist
    let backgroundAppRefreshTaskIdentifier = "io.element.elementx.background.refresh"

    /// A URL where users can go read more about the app.
    let websiteURL: URL = "https://element.io"
    /// A URL that contains the app's logo that may be used when showing content in a web view.
    let logoURL: URL = "https://element.io/mobile-icon.png"
    /// A URL that contains that app's copyright notice.
    let copyrightURL: URL = "https://element.io/copyright"
    /// A URL that contains the app's Terms of use.
    let acceptableUseURL: URL = "https://element.io/acceptable-use-policy-terms"
    /// A URL that contains the app's Privacy Policy.
    let privacyURL: URL = "https://element.io/privacy"
    /// An email address that should be used for support requests.
    let supportEmailAddress = "support@element.io"
    /// A URL where users can go read more about encryption in general.
    let encryptionURL: URL = "https://element.io/help#encryption"
    /// A URL where users can go read more about the chat backup.
    let chatBackupDetailsURL: URL = "https://element.io/help#encryption5"
    /// Any domains that Element web may be hosted on - used for handling links.
    let elementWebHosts = ["app.element.io", "staging.element.io", "develop.element.io"]
    
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
    
    /// The URL that is opened when tapping the Learn more button on the sliding sync alert during authentication.
    let slidingSyncLearnMoreURL: URL = "https://github.com/matrix-org/sliding-sync/blob/main/docs/Landing.md"
    
    /// Any pre-defined static client registrations for OIDC issuers.
    let oidcStaticRegistrations: [URL: String] = ["https://id.thirdroom.io/realms/thirdroom": "elementx"]
    /// The redirect URL used for OIDC.
    let oidcRedirectURL = {
        guard let url = URL(string: "\(InfoPlistReader.main.appScheme):/callback") else {
            fatalError("Invalid OIDC redirect URL")
        }
        
        return url
    }()
    
    private(set) lazy var oidcConfiguration = OIDCConfigurationProxy(clientName: InfoPlistReader.main.bundleDisplayName,
                                                                     redirectURI: oidcRedirectURL,
                                                                     clientURI: websiteURL,
                                                                     logoURI: logoURL,
                                                                     tosURI: acceptableUseURL,
                                                                     policyURI: privacyURL,
                                                                     contacts: [supportEmailAddress],
                                                                     staticRegistrations: oidcStaticRegistrations.mapKeys { $0.absoluteString },
                                                                     dynamicRegistrationsFile: .sessionsBaseDirectory.appending(path: "oidc/registrations.json"))
    
    /// A temporary hack to allow registration on matrix.org until MAS is deployed.
    let webRegistrationEnabled = true
    
    // MARK: - Notifications
    
    var pusherAppId: String {
        #if DEBUG
        InfoPlistReader.main.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.main.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    let pushGatewayBaseURL: URL = "https://matrix.org/_matrix/push/v1/notify"
    
    @UserPreference(key: UserDefaultsKeys.enableNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableNotifications

    @UserPreference(key: UserDefaultsKeys.enableInAppNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableInAppNotifications

    /// Tag describing which set of device specific rules a pusher executes.
    @UserPreference(key: UserDefaultsKeys.pusherProfileTag, storageType: .userDefaults(store))
    var pusherProfileTag: String?
        
    // MARK: - Bug report

    let bugReportServiceBaseURL: URL = "https://riot.im/bugreports"
    let bugReportSentryURL: URL = "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44"
    // Use the name allocated by the bug report server
    let bugReportApplicationId = "element-x-ios"
    /// The maximum size of the upload request. Default value is just below CloudFlare's max request size.
    let bugReportMaxUploadSize = 50 * 1024 * 1024
    
    // MARK: - Analytics
    
    #if DEBUG
    /// The configuration to use for analytics during development. Set `isEnabled` to false to disable analytics in debug builds.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element."),
                                                        host: "https://posthog.element.dev",
                                                        apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                        termsURL: "https://element.io/cookie-policy")
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element."),
                                                        host: "https://posthog.element.io",
                                                        apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                        termsURL: URL("https://element.io/cookie-policy"))
    #endif
        
    /// Whether the user has opted in to send analytics.
    @UserPreference(key: UserDefaultsKeys.analyticsConsentState, defaultValue: AnalyticsConsentState.unknown, storageType: .userDefaults(store))
    var analyticsConsentState
    
    @UserPreference(key: UserDefaultsKeys.hasRunNotificationPermissionsOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunNotificationPermissionsOnboarding
    
    @UserPreference(key: UserDefaultsKeys.hasRunIdentityConfirmationOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunIdentityConfirmationOnboarding
    
    // MARK: - Home Screen
    
    @UserPreference(key: UserDefaultsKeys.hideUnreadMessagesBadge, defaultValue: false, storageType: .userDefaults(store))
    var hideUnreadMessagesBadge
    
    // MARK: - Room Screen
    
    @UserPreference(key: UserDefaultsKeys.viewSourceEnabled, defaultValue: isDevelopmentBuild, storageType: .userDefaults(store))
    var viewSourceEnabled

    // MARK: - Element Call
    
    let elementCallBaseURL: URL = "https://call.element.io"
    
    @UserPreference(key: UserDefaultsKeys.elementCallBaseURLOverride, defaultValue: nil, storageType: .userDefaults(store))
    var elementCallBaseURLOverride: URL?
    
    // MARK: - Users
    
    /// Whether to hide the display name and avatar of ignored users as these may contain objectionable content.
    let hideIgnoredUserProfiles = true
    
    // MARK: - Maps
    
    // maptiler base url
    let mapTilerBaseURL: URL = "https://api.maptiler.com/maps"

    // maptiler api key
    let mapTilerApiKey = InfoPlistReader.main.mapLibreAPIKey
    
    // MARK: - Presence

    @UserPreference(key: UserDefaultsKeys.sharePresence, defaultValue: true, storageType: .userDefaults(store))
    var sharePresence
    
    // MARK: - Feature Flags
    
    @UserPreference(key: UserDefaultsKeys.publicSearchEnabled, defaultValue: isDevelopmentBuild, storageType: .volatile)
    var publicSearchEnabled
    
    @UserPreference(key: UserDefaultsKeys.fuzzyRoomListSearchEnabled, defaultValue: false, storageType: .userDefaults(store))
    var fuzzyRoomListSearchEnabled
    
    @UserPreference(key: UserDefaultsKeys.pinningEnabled, defaultValue: true, storageType: .userDefaults(store))
    var pinningEnabled
    
    enum SlidingSyncDiscovery: Codable { case proxy, native, forceNative }
    @UserPreference(key: UserDefaultsKeys.slidingSyncDiscovery, defaultValue: .native, storageType: .userDefaults(store))
    var slidingSyncDiscovery: SlidingSyncDiscovery

    #endif
    
    // MARK: - Shared
        
    @UserPreference(key: UserDefaultsKeys.logLevel, defaultValue: TracingConfiguration.LogLevel.info, storageType: .userDefaults(store))
    var logLevel
    
    /// Configuration to enable invisible crypto. In this mode only devices signed by their owner will be considered in e2ee rooms.
    @UserPreference(key: UserDefaultsKeys.invisibleCryptoEnabled, defaultValue: false, storageType: .userDefaults(store))
    var invisibleCryptoEnabled
}

extension AppSettings: CommonSettingsProtocol { }
