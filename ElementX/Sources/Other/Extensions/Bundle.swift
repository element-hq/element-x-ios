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

public extension Bundle {
    /// The top-level bundle that contains the entire app.
    static var app: Bundle {
        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        return bundle
    }
    
    // MARK: - Localisation
    
    private static var cachedLocalizationBundles = [String: Bundle]()
    
    /// Get an lproj language bundle from the receiver bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise nil.
    static func lprojBundle(for language: String) -> Bundle? {
        if let bundle = cachedLocalizationBundles[language] {
            return bundle
        }
        
        guard let lprojURL = Bundle.app.url(forResource: language, withExtension: "lproj") else {
            return nil
        }
        
        let bundle = Bundle(url: lprojURL)
        cachedLocalizationBundles[language] = bundle
        
        return bundle
    }

    /// Overrides `Bundle.app.preferredLocalizations` for testing translations.
    static var overrideLocalizations: [String]?
}
