//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftUI

/// Store Element specific app settings.
final class AppSettings {
    private enum UserDefaultsKeys: String {
        case lastVersionLaunched
        case seenInvites
        case hasShownWelcomeScreen
        case appLockNumberOfPINAttempts
        case appLockNumberOfBiometricAttempts
        case lastLoginDate
        case migratedAccounts
        case timelineStyle
        case analyticsConsentState
        case enableNotifications
        case enableInAppNotifications
        case pusherProfileTag
        case logLevel
        case otlpTracingEnabled
        case viewSourceEnabled
        case richTextEditorEnabled
        
        case elementCallBaseURL
        case elementCallEncryptionEnabled
        
        // Feature flags
        case shouldCollapseRoomStateEvents
        case userSuggestionsEnabled
        case readReceiptsEnabled
        case swiftUITimelineEnabled
        case chatBackupEnabled
    }
    
    private static var suiteName: String = InfoPlistReader.main.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    static func reset() {
        MXLog.warning("Resetting the AppSettings.")
        store.removePersistentDomain(forName: suiteName)
    }
    
    static func configureWithSuiteName(_ name: String) {
        suiteName = name
        
        guard let userDefaults = UserDefaults(suiteName: name) else {
            fatalError("Fail to load shared UserDefaults")
        }
        
        store = userDefaults
    }
    
    // MARK: - Application
    
    lazy var canShowDeveloperOptions: Bool = {
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

    let lastLaunchDate = Date()
    
    /// The Set of room identifiers of invites that the user already saw in the invites list.
    /// This Set is being used to implement badges for unread invites.
    @UserPreference(key: UserDefaultsKeys.seenInvites, defaultValue: [], storageType: .userDefaults(store))
    var seenInvites: Set<String>
    
    /// The default homeserver address used. This is intentionally a string without a scheme
    /// so that it can be passed to Rust as a ServerName for well-known discovery.
    let defaultHomeserverAddress = "matrix.org"
    
    /// An override of the homeserver's Sliding Sync proxy URL. This allows development against servers
    /// that don't yet have an officially trusted proxy configured in their well-known.
    let slidingSyncProxyURL: URL? = nil
    
    /// The task identifier used for background app refresh. Also used in main target's the Info.plist
    let backgroundAppRefreshTaskIdentifier = "io.element.elementx.background.refresh"

    @UserPreference(key: UserDefaultsKeys.hasShownWelcomeScreen, defaultValue: false, storageType: .userDefaults(store))
    var hasShownWelcomeScreen: Bool
    
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
    // A URL where users can go read more about the chat backup.
    let chatBackupDetailsURL: URL = "https://element.io/help#encryption5"
    
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
    let oidcRedirectURL: URL = "io.element:/callback"

    /// The date that the call to `/login` completed successfully. This is used to put
    /// a hard wall on the history of encrypted messages until we have key backup.
    ///
    /// Not a multi-account aware setting as key backup will come before multi-account.
    @UserPreference(key: UserDefaultsKeys.lastLoginDate, defaultValue: nil, storageType: .userDefaults(store))
    var lastLoginDate: Date?
    
    /// A dictionary of accounts that have performed an initial sync through their proxy.
    ///
    /// This is a temporary workaround. In the future we should be able to receive a signal from the
    /// proxy that it is the first sync (or that an upgrade on the backend will involve a slower sync).
    @UserPreference(key: UserDefaultsKeys.migratedAccounts, defaultValue: [:], storageType: .userDefaults(store))
    var migratedAccounts: [String: Bool]

    // MARK: - Notifications
    
    var pusherAppId: String {
        #if DEBUG
        InfoPlistReader.main.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.main.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    let pushGatewayBaseURL: URL = "https://matrix.org/_matrix/push/v1/notify"
        
    // MARK: - Bug report

    let bugReportServiceBaseURL: URL = "https://riot.im/bugreports"
    let bugReportSentryURL: URL = "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44"
    // Use the name allocated by the bug report server
    let bugReportApplicationId = "element-x-ios"
    let bugReportUISIId = "element-auto-uisi"
    /// The maximum size of the upload request. Default value is just below CloudFlare's max request size.
    let bugReportMaxUploadSize = 50 * 1024 * 1024
    
    // MARK: - Analytics
    
    #if DEBUG
    /// The configuration to use for analytics during development. Set `isEnabled` to false to disable analytics in debug builds.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.element.dev",
                                                        apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                        termsURL: "https://element.io/cookie-policy")
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.element.io",
                                                        apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                        termsURL: URL("https://element.io/cookie-policy"))
    #endif
        
    /// Whether the user has opted in to send analytics.
    @UserPreference(key: UserDefaultsKeys.analyticsConsentState, defaultValue: AnalyticsConsentState.unknown, storageType: .userDefaults(store))
    var analyticsConsentState
    
    // MARK: - Room Screen
    
    @UserPreference(key: UserDefaultsKeys.timelineStyle, defaultValue: TimelineStyle.bubbles, storageType: .userDefaults(store))
    var timelineStyle
    
    @UserPreference(key: UserDefaultsKeys.shouldCollapseRoomStateEvents, defaultValue: true, storageType: .volatile)
    var shouldCollapseRoomStateEvents
    
    @UserPreference(key: UserDefaultsKeys.viewSourceEnabled, defaultValue: false, storageType: .userDefaults(store))
    var viewSourceEnabled

    @UserPreference(key: UserDefaultsKeys.richTextEditorEnabled, defaultValue: true, storageType: .userDefaults(store))
    var richTextEditorEnabled
    
    // MARK: - Element Call
    
    @UserPreference(key: UserDefaultsKeys.elementCallBaseURL, defaultValue: "https://call.element.io", storageType: .userDefaults(store))
    var elementCallBaseURL: URL
    
    @UserPreference(key: UserDefaultsKeys.elementCallEncryptionEnabled, defaultValue: true, storageType: .userDefaults(store))
    var elementCallUseEncryption
    
    // MARK: - Notifications

    @UserPreference(key: UserDefaultsKeys.enableNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableNotifications

    @UserPreference(key: UserDefaultsKeys.enableInAppNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableInAppNotifications

    /// Tag describing which set of device specific rules a pusher executes.
    @UserPreference(key: UserDefaultsKeys.pusherProfileTag, storageType: .userDefaults(store))
    var pusherProfileTag: String?
        
    // MARK: - Other
    
    let permalinkBaseURL: URL = "https://matrix.to"
    
    // MARK: - Logging
    
    @UserPreference(key: UserDefaultsKeys.logLevel, defaultValue: TracingConfiguration.LogLevel.info, storageType: .userDefaults(store))
    var logLevel
    
    @UserPreference(key: UserDefaultsKeys.otlpTracingEnabled, defaultValue: false, storageType: .userDefaults(store))
    var otlpTracingEnabled
    
    let otlpTracingURL = InfoPlistReader.main.otlpTracingURL
    let otlpTracingUsername = InfoPlistReader.main.otlpTracingUsername
    let otlpTracingPassword = InfoPlistReader.main.otlpTracingPassword
    
    // MARK: - Maps
    
    // maptiler base url
    let mapTilerBaseURL: URL = "https://api.maptiler.com/maps"

    // maptiler api key
    let mapTilerApiKey = InfoPlistReader.main.mapLibreAPIKey
    
    // maptiler geocoding url
    let geocodingURLFormatString = "https://api.maptiler.com/geocoding/%f,%f.json"
    
    // MARK: - Feature Flags
    
    @UserPreference(key: UserDefaultsKeys.userSuggestionsEnabled, defaultValue: false, storageType: .volatile)
    var userSuggestionsEnabled

    @UserPreference(key: UserDefaultsKeys.readReceiptsEnabled, defaultValue: false, storageType: .userDefaults(store))
    var readReceiptsEnabled
    
    @UserPreference(key: UserDefaultsKeys.swiftUITimelineEnabled, defaultValue: false, storageType: .volatile)
    var swiftUITimelineEnabled
    
    @UserPreference(key: UserDefaultsKeys.chatBackupEnabled, defaultValue: false, storageType: .userDefaults(store))
    var chatBackupEnabled
}
