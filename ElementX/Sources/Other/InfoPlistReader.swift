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

struct InfoPlistReader {
    private enum Keys {
        static let appGroupIdentifier = "appGroupIdentifier"
        static let baseBundleIdentifier = "baseBundleIdentifier"
        static let bundleShortVersion = "CFBundleShortVersionString"
        static let bundleDisplayName = "CFBundleDisplayName"
    }

    /// Info.plist reader on the current target
    static let target = InfoPlistReader(bundle: .main)

    private let bundle: Bundle

    /// Initializer
    /// - Parameter bundle: bundle to read values from
    init(bundle: Bundle) {
        self.bundle = bundle
    }

    /// App group identifier set in Info.plist of the target
    var appGroupIdentifier: String {
        infoPlistStringValue(forKey: Keys.appGroupIdentifier)
    }

    /// Base bundle identifier set in Info.plist of the target
    var baseBundleIdentifier: String {
        infoPlistStringValue(forKey: Keys.baseBundleIdentifier)
    }

    /// Bundle executable of the target
    var bundleExecutable: String {
        infoPlistStringValue(forKey: kCFBundleExecutableKey as String)
    }

    /// Bundle identifier of the target
    var bundleIdentifier: String {
        infoPlistStringValue(forKey: kCFBundleIdentifierKey as String)
    }

    /// Bundle short version string of the target
    var bundleShortVersionString: String {
        infoPlistStringValue(forKey: Keys.bundleShortVersion)
    }

    /// Bundle version of the target
    var bundleVersion: String {
        infoPlistStringValue(forKey: kCFBundleVersionKey as String)
    }

    /// Bundle display name of the target
    var bundleDisplayName: String {
        infoPlistStringValue(forKey: Keys.bundleDisplayName)
    }

    private func infoPlistStringValue(forKey key: String) -> String {
        guard let result = bundle.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Add \(key) into your target's Info.plst")
        }
        return result
    }
}
