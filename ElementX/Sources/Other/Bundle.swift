//
//  Bundle.swift
//  ElementX
//
//  Created by Ismail on 15.04.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation

public extension Bundle {
    /// Returns the real app bundle.
    /// Can also be used in app extensions.
    @objc static let app: Bundle = {
        let bundle = main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                return otherBundle
            }
        }
        return bundle
    }()

    /// Get an lproj language bundle from the main app bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise `nil`.
    @objc static func lprojBundle(for language: String) -> Bundle? {
        guard let lprojURL = Bundle.app.url(forResource: language, withExtension: "lproj") else { return nil }
        return Bundle(url: lprojURL)
    }

    /// Whether or not the bundle is the ElementShareExtension.
    var isShareExtension: Bool {
        bundleURL.lastPathComponent.contains("ElementShareExtension.appex")
    }
}
