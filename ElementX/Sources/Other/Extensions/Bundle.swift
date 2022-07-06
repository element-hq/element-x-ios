//
//  Bundle.swift
//  ElementX
//
//  Created by Ismail on 15.04.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

public extension Bundle {

    /// Get an lproj language bundle from the receiver bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise nil.
    func lprojBundle(for language: String) -> Bundle? {
        guard let lprojURL = url(forResource: language, withExtension: "lproj") else { return nil }
        return Bundle(url: lprojURL)
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
