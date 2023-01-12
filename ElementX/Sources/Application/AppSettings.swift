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
        case hasAppLaunchedOnce
        case timelineStyle
        case enableAnalytics
        case isIdentifiedForAnalytics
        case slidingSyncProxyBaseURLString
        case enableInAppNotifications
        case pusherProfileTag
    }
    
    private static var suiteName: String = InfoPlistReader.target.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    static func reset() {
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
    
    /// Simple flag to check if app has been deleted between runs.
    /// Used to clear data stored in the shared container and keychain
    @AppStorage(UserDefaultsKeys.hasAppLaunchedOnce.rawValue, store: store)
    var hasAppLaunchedOnce = false
    
    let defaultHomeserverAddress = "matrix.org"
    
    // MARK: - Notifications
    
    var pusherAppId: String {
        #if DEBUG
        InfoPlistReader.target.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.target.baseBundleIdentifier + ".ios.prod"
        #endif
    }
    
    let pushGatewayBaseURL = URL(staticString: "https://matrix.org/_matrix/push/v1/notify")
    
    let enableNotifications = false
    
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
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.target.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.element.dev",
                                                        apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                        termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.target.bundleIdentifier.starts(with: "io.element.elementx"),
                                                        host: "https://posthog.hss.element.io",
                                                        apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                        termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #endif
    
    /// Whether the user has already been shown the PostHog analytics prompt.
    var hasSeenAnalyticsPrompt: Bool {
        Self.store.object(forKey: UserDefaultsKeys.enableAnalytics.rawValue) != nil
    }
    
    /// `true` when the user has opted in to send analytics.
    @AppStorage(UserDefaultsKeys.enableAnalytics.rawValue, store: store)
    var enableAnalytics = false
    
    /// Indicates if the device has already called identify for this session to PostHog.
    /// This is separate to `enableAnalytics` as logging out leaves analytics
    /// enabled, but requires the next account to be identified separately.
    @AppStorage(UserDefaultsKeys.isIdentifiedForAnalytics.rawValue, store: store)
    var isIdentifiedForAnalytics = false
    
    // MARK: - Room Screen
    
    @AppStorage(UserDefaultsKeys.timelineStyle.rawValue, store: store)
    var timelineStyle = TimelineStyle.bubbles

    // MARK: - Client

    @AppStorage(UserDefaultsKeys.slidingSyncProxyBaseURLString.rawValue, store: store)
    var slidingSyncProxyBaseURLString = "https://slidingsync.lab.element.dev"

    // MARK: - Notifications

    @AppStorage(UserDefaultsKeys.enableInAppNotifications.rawValue, store: store)
    var enableInAppNotifications = true

    /// Tag describing which set of device specific rules a pusher executes.
    @AppStorage(UserDefaultsKeys.pusherProfileTag.rawValue, store: store)
    var pusherProfileTag: String?
        
    // MARK: - Other
    
    let permalinkBaseURL = URL(staticString: "https://matrix.to")
}
