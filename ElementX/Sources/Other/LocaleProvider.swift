//
//  LocaleProvider.swift
//  ElementX
//
//  Created by Ismail on 15.04.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation

/**
 Used to provide an application/target specific locale.
 */
protocol LocaleProviderType {
    /// Returns the locale specified with `Bundle.elementLanguage` if provided, otherwise `current`.
    static var preferredLocale: Locale { get }

    /// Returns the locale specified with `Bundle.elementFallbackLanguage` if provided, otherwise `preferredLocale`.
    static var fallbackLocale: Locale { get }
}

/**
 Provides the locale logic for Element app based on languages.
 */
class LocaleProvider: LocaleProviderType {

    static var preferredLocale: Locale {
        guard let localeIdentifier = Bundle.elementLanguage else {
            return .current
        }
        return Locale(identifier: localeIdentifier)
    }

    static var fallbackLocale: Locale {
        guard let fallbackLocaleIdentifier = Bundle.elementFallbackLanguage else {
            return Self.preferredLocale
        }
        return Locale(identifier: fallbackLocaleIdentifier)
    }

}
