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
        static let keychainAccessGroupIdentifier = "keychainAccessGroupIdentifier"
        static let bundleShortVersion = "CFBundleShortVersionString"
        static let bundleDisplayName = "CFBundleDisplayName"
        static let mapLibreAPIKey = "mapLibreAPIKey"
        static let utExportedTypeDeclarationsKey = "UTExportedTypeDeclarations"
        static let utTypeIdentifierKey = "UTTypeIdentifier"
        static let utDescriptionKey = "UTTypeDescription"
        
        static let otlpTracingURL = "otlpTracingURL"
        static let otlpTracingUsername = "otlpTracingUsername"
        static let otlpTracingPassword = "otlpTracingPassword"
        
        static let bundleURLTypes = "CFBundleURLTypes"
        static let bundleURLName = "CFBundleURLName"
        static let bundleURLSchemes = "CFBundleURLSchemes"
    }
    
    private enum Values {
        static let mentionPills = "Mention Pills"
    }

    /// Info.plist reader on the bundle object that contains the current executable.
    static let main = InfoPlistReader(bundle: .main)

    /// Info.plist reader on the bundle object that contains the main app executable.
    static let app = InfoPlistReader(bundle: .app)

    private let bundle: Bundle

    /// Initializer
    /// - Parameter bundle: bundle to read values from
    init(bundle: Bundle) {
        self.bundle = bundle
    }

    /// App group identifier set in Info.plist of the target
    var appGroupIdentifier: String {
        infoPlistValue(forKey: Keys.appGroupIdentifier)
    }

    /// Base bundle identifier set in Info.plist of the target
    var baseBundleIdentifier: String {
        infoPlistValue(forKey: Keys.baseBundleIdentifier)
    }
    
    /// Keychain access group identifier set in Info.plist of the target
    var keychainAccessGroupIdentifier: String {
        infoPlistValue(forKey: Keys.keychainAccessGroupIdentifier)
    }

    /// Bundle executable of the target
    var bundleExecutable: String {
        infoPlistValue(forKey: kCFBundleExecutableKey as String)
    }

    /// Bundle identifier of the target
    var bundleIdentifier: String {
        infoPlistValue(forKey: kCFBundleIdentifierKey as String)
    }

    /// Bundle short version string of the target
    var bundleShortVersionString: String {
        infoPlistValue(forKey: Keys.bundleShortVersion)
    }

    /// Bundle version of the target
    var bundleVersion: String {
        infoPlistValue(forKey: kCFBundleVersionKey as String)
    }

    /// Bundle display name of the target
    var bundleDisplayName: String {
        infoPlistValue(forKey: Keys.bundleDisplayName)
    }

    // MARK: - MapLibre
    
    var mapLibreAPIKey: String {
        infoPlistValue(forKey: Keys.mapLibreAPIKey)
    }
    
    // MARK: - OTLP Tracing
    
    var otlpTracingURL: String {
        infoPlistValue(forKey: Keys.otlpTracingURL)
    }
    
    var otlpTracingUsername: String {
        infoPlistValue(forKey: Keys.otlpTracingUsername)
    }
    
    var otlpTracingPassword: String {
        infoPlistValue(forKey: Keys.otlpTracingPassword)
    }
    
    // MARK: - Custom App Scheme
    
    var appScheme: String {
        customSchemeForName("Application")
    }
    
    var elementCallScheme: String {
        customSchemeForName("Element Call")
    }
    
    // MARK: - Mention Pills

    /// Mention Pills UTType
    var pillsUTType: String {
        let exportedTypes: [[String: Any]] = infoPlistValue(forKey: Keys.utExportedTypeDeclarationsKey)
        guard let mentionPills = exportedTypes.first(where: { $0[Keys.utDescriptionKey] as? String == Values.mentionPills }),
              let utType = mentionPills[Keys.utTypeIdentifierKey] as? String else {
            fatalError("Add properly \(Values.mentionPills) exported type into your target's Info.plst")
        }
        return utType
    }
    
    // MARK: - Private
    
    private func infoPlistValue<T>(forKey key: String) -> T {
        guard let result = bundle.object(forInfoDictionaryKey: key) as? T else {
            fatalError("Add \(key) into your target's Info.plst")
        }
        return result
    }
    
    private func customSchemeForName(_ name: String) -> String {
        let urlTypes: [[String: Any]] = infoPlistValue(forKey: Keys.bundleURLTypes)
        
        guard let urlType = urlTypes.first(where: { $0[Keys.bundleURLName] as? String == name }),
              let urlSchemes = urlType[Keys.bundleURLSchemes] as? [String],
              let scheme = urlSchemes.first else {
            fatalError("Invalid custom application scheme configuration")
        }
        
        return scheme
    }
}
