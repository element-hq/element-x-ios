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
final class ApplicationSettings: ObservableObject {
    // MARK: - Constants

    private enum UserDefaultsKeys: String {
        case wasAppPreviouslyRan
        case timelineStyle
        case enableAnalytics
        case isIdentifiedForAnalytics
        case slidingSyncProxyBaseURLString
        case enableInAppNotifications
        case pusherProfileTag
    }

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: InfoPlistReader.target.appGroupIdentifier) else {
            fatalError("Fail to load shared UserDefaults")
        }
        return userDefaults
    }
    
    static func reset() {
        let dictionary = Self.store.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            Self.store.removeObject(forKey: key)
        }
    }
    
    // MARK: - Application
    
    /// Simple flag to check if app has been deleted between runs.
    /// Used to clear data stored in the shared container and keychain
    @AppStorage(UserDefaultsKeys.wasAppPreviouslyRan.rawValue, store: store)
    var wasAppPreviouslyRan = false
    
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

    /// Tag describing which set of device specific rules a pusher executes.
    @AppStorage(UserDefaultsKeys.pusherProfileTag.rawValue, store: store)
    var pusherProfileTag: String?
}
