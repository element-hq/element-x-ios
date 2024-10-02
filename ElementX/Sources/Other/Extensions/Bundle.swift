//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    /// Overrides `Bundle.app.preferredLocalizations` for testing translations.
    static var overrideLocalizations: [String]?
    
    private static let cacheDispatchQueue = DispatchQueue(label: "io.element.elementx.localization_bundle_cache")
    private static var cachedBundles = [String: Bundle]()
    
    /// Get an lproj language bundle from the receiver bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise nil.
    static func lprojBundle(for language: String) -> Bundle? {
        if let bundle = cachedValue(forKey: language) {
            return bundle
        }
        
        guard let lprojURL = Bundle.app.url(forResource: language, withExtension: "lproj") else {
            return nil
        }
        
        let bundle = Bundle(url: lprojURL)
        
        cacheValue(bundle, forKey: language)
        
        return bundle
    }
    
    // MARK: - Private
    
    private static func cacheValue(_ value: Bundle?, forKey key: String) {
        cacheDispatchQueue.sync {
            cachedBundles[key] = value
        }
    }
    
    private static func cachedValue(forKey key: String) -> Bundle? {
        var result: Bundle?
        cacheDispatchQueue.sync {
            result = cachedBundles[key]
        }
        
        return result
    }
}
