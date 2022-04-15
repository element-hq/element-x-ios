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
    static var locale: Locale? { get }
}

/**
 Provides the locale logic for Riot app based on mx languages.
 */
class LocaleProvider: LocaleProviderType {
    static var locale: Locale? {
        if let localeIdentifier = Bundle.mxk_language() {
            return Locale(identifier: localeIdentifier)
        } else if let fallbackLocaleIdentifier = Bundle.mxk_fallbackLanguage() {
            return Locale(identifier: fallbackLocaleIdentifier)
        }
        return nil
    }
}
