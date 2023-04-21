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
final class AppSettings: ObservableObject {
    private enum UserDefaultsKeys: String {
        case lastVersionLaunched
        case timelineStyle
        case enableAnalytics
        case enableInAppNotifications
        case pusherProfileTag
        case shouldCollapseRoomStateEvents
        case startChatFlowEnabled
        case startChatUserSuggestionsEnabled
        case mediaUploadingFlowEnabled
        case invitesFlowEnabled
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
    
    /// The default homeserver address used. This is intentionally a string without a scheme
    /// so that it can be passed to Rust as a ServerName for well-known discovery.
    let defaultHomeserverAddress = "matrix.org"
    
    /// An override of the homeserver's Sliding Sync proxy URL. This allows development against servers
    /// that don't yet have an officially trusted proxy configured in their well-known.
    let slidingSyncProxyURL: URL? = nil
    
    // MARK: - Authentication
    
    /// The URL that is opened when tapping the Learn more button on the sliding sync alert during authentication.
    let slidingSyncLearnMoreURL = URL(staticString: "https://github.com/matrix-org/sliding-sync/blob/main/docs/Landing.md")
    
    // MARK: - Notifications
    
    var pusherAppId: String {
        #if DEBUG
        InfoPlistReader.main.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.main.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    let pushGatewayBaseURL = URL(staticString: "https://matrix.org/_matrix/push/v1/notify")
        
    // MARK: - Bug report

    let bugReportServiceBaseURL = URL(staticString: "https://riot.im/bugreports")
    let bugReportSentryURL = URL(staticString: "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44")
    // Use the name allocated by the bug report server
    let bugReportApplicationId = "element-x-ios"
    let bugReportUISIId = "element-auto-uisi"
    
    // MARK: - Analytics
        
    #if DEBUG
    /// The configuration to use for analytics during development. Set `isEnabled` to false to disable analytics in debug builds.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.element.dev",
                                                        apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                        termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.main.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.hss.element.io",
                                                        apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                        termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #endif
    
    /// Whether the user has already been shown the PostHog analytics prompt.
    var hasSeenAnalyticsPrompt: Bool {
        Self.store.object(forKey: UserDefaultsKeys.enableAnalytics.rawValue) != nil
    }
    
    /// `true` when the user has opted in to send analytics.
    @UserPreference(key: UserDefaultsKeys.enableAnalytics, defaultValue: false, storageType: .userDefaults(store))
    var enableAnalytics
        
    // MARK: - Room Screen
    
    @UserPreference(key: UserDefaultsKeys.timelineStyle, defaultValue: TimelineStyle.bubbles, storageType: .userDefaults(store))
    var timelineStyle
    
    @UserPreference(key: UserDefaultsKeys.shouldCollapseRoomStateEvents, defaultValue: true, storageType: .volatile)
    var shouldCollapseRoomStateEvents
    
    // MARK: - Notifications

    @UserPreference(key: UserDefaultsKeys.timelineStyle, defaultValue: true, storageType: .userDefaults(store))
    var enableInAppNotifications

    /// Tag describing which set of device specific rules a pusher executes.
    @UserPreference(key: UserDefaultsKeys.pusherProfileTag, storageType: .userDefaults(store))
    var pusherProfileTag: String?
        
    // MARK: - Other
    
    let permalinkBaseURL = URL(staticString: "https://matrix.to")
    
    // MARK: - Feature Flags
    
    // MARK: Start Chat
    
    @UserPreference(key: UserDefaultsKeys.startChatFlowEnabled, defaultValue: false, storageType: .userDefaults(store))
    var startChatFlowEnabled
    
    @UserPreference(key: UserDefaultsKeys.startChatUserSuggestionsEnabled, defaultValue: false, storageType: .volatile)
    var startChatUserSuggestionsEnabled
    
    // MARK: Media Uploading
    
    @UserPreference(key: UserDefaultsKeys.mediaUploadingFlowEnabled, defaultValue: false, storageType: .volatile)
    var mediaUploadingFlowEnabled
    
    // MARK: Invites
    
    @UserPreference(key: UserDefaultsKeys.invitesFlowEnabled, defaultValue: false, storageType: .userDefaults(store))
    var invitesFlowEnabled
}
