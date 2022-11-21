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

final class BuildSettings {
    // MARK: - Bundle Settings

    static var pusherAppId: String {
        #if DEBUG
        InfoPlistReader.target.baseBundleIdentifier + ".ios.dev"
        #else
        InfoPlistReader.target.baseBundleIdentifier + ".ios.prod"
        #endif
    }

    // MARK: - Servers

    static let defaultHomeserverAddress = "matrix.org"
    static let defaultSlidingSyncProxyBaseURLString = "https://slidingsync.lab.element.dev"
    static let pushGatewayBaseURL = URL(staticString: "https://matrix.org/_matrix/push/v1/notify")

    // MARK: - Bug report

    static let bugReportServiceBaseURL = URL(staticString: "https://riot.im/bugreports")
    static let bugReportSentryURL = URL(staticString: "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44")
    // Use the name allocated by the bug report server
    static let bugReportApplicationId = "riot-ios"
    static let bugReportUISIId = "element-auto-uisi"

    static let bugReportGHLabels = ["Element-X"]

    // MARK: - Analytics
    
    #if DEBUG
    /// The configuration to use for analytics during development. Set `isEnabled` to false to disable analytics in debug builds.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    static let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.target.bundleIdentifier.starts(with: "io.element.elementx"),
                                                               host: "https://posthog.element.dev",
                                                               apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                               termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    /// **Note:** Analytics are disabled by default for forks. If you are maintaining a fork, set custom configurations.
    static let analyticsConfiguration = AnalyticsConfiguration(isEnabled: InfoPlistReader.target.bundleIdentifier.starts(with: "io.element.elementx"),
                                                               host: "https://posthog.hss.element.io",
                                                               apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                               termsURL: URL(staticString: "https://element.io/cookie-policy"))
    #endif

    // MARK: - Settings screen

    static let settingsCrashButtonVisible = true
    static let settingsShowTimelineStyle = true

    // MARK: - Room screen

    static let defaultRoomTimelineStyle: TimelineStyle = .bubbles
    
    // MARK: - Other
    
    static var permalinkBaseURL = URL(staticString: "https://matrix.to")

    // MARK: - Notifications

    static let enableNotifications = false
}
