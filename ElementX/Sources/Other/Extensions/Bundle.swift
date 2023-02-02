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
    private static var cachedLocalizationBundles = [String: Bundle]()
    
    /// Get an lproj language bundle from the receiver bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise nil.
    func lprojBundle(for language: String) -> Bundle? {
        if let bundle = Self.cachedLocalizationBundles[language] {
            return bundle
        }
        
        guard let lprojURL = url(forResource: language, withExtension: "lproj") else {
            return nil
        }
        
        let bundle = Bundle(url: lprojURL)
        Self.cachedLocalizationBundles[language] = bundle
        
        return bundle
    }

    /// Preferred app language for translations. Takes the highest priority in translations. The priority list for translations:
    /// - `Bundle.elementLanguage`
    /// - `Locale.preferredLanguages`
    /// - `Bundle.elementFallbackLanguage`
    static var elementLanguage: String? {
        didSet {
            preferredLanguages = calculatePreferredLanguages()
        }
    }

    /// Preferred fallback language for translations. Only used for strings not translated neither to `elementLanguage` nor to one of the user's preferred languages.
    static var elementFallbackLanguage: String? {
        didSet {
            preferredLanguages = calculatePreferredLanguages()
        }
    }

    /// Preferred languages in the priority order.
    private(set) static var preferredLanguages: [String] = calculatePreferredLanguages()

    private static func calculatePreferredLanguages() -> [String] {
        var set = Set<String>()
        return ([Bundle.elementLanguage] +
            Locale.preferredLanguages +
            [Bundle.elementFallbackLanguage])
            .compactMap { $0 }
            .filter { set.insert($0).inserted }
    }
}
