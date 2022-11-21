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
final class ElementSettings: ObservableObject {
    // MARK: - Constants

    public enum UserDefaultsKeys: String {
        case timelineStyle
        case enableAnalytics
        case isIdentifiedForAnalytics
        case slidingSyncProxyBaseURLString
        case enableInAppNotifications
        case pusherProfileTag
    }

    static let shared = ElementSettings()

    /// UserDefaults to be used on reads and writes.
    static var store: UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: InfoPlistReader.target.appGroupIdentifier) else {
            fatalError("Fail to load shared UserDefaults")
        }
        return userDefaults
    }

    private init() {
        // no-op
    }
    
    // MARK: - Analytics
    
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
    var timelineStyle = BuildSettings.defaultRoomTimelineStyle

    // MARK: - Client

    @AppStorage(UserDefaultsKeys.slidingSyncProxyBaseURLString.rawValue, store: store)
    var slidingSyncProxyBaseURLString = BuildSettings.defaultSlidingSyncProxyBaseURLString

    // MARK: - Notifications

    @AppStorage(UserDefaultsKeys.enableInAppNotifications.rawValue, store: store)
    var enableInAppNotifications = true

    @AppStorage(UserDefaultsKeys.pusherProfileTag.rawValue, store: store)
    /// Tag describing which set of device specific rules a pusher executes.
    var pusherProfileTag: String?
}
