//
// Copyright 2023 New Vector Ltd
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

final class NSESettings {
    private static var suiteName: String = InfoPlistReader.main.appGroupIdentifier

    /// UserDefaults to be used on reads and writes.
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)

    /// A set of all the notification identifiers that have been served so far, it's reset every time the app is launched
    @UserPreference(key: SharedUserDefaultsKeys.servedNotificationIdentifiers, defaultValue: [], storageType: .userDefaults(store))
    var servedNotificationIdentifiers: Set<String>
}
