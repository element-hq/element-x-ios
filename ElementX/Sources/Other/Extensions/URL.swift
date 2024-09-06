//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        guard let url = URL(string: "\(value)") else {
            fatalError("The static string used to create this URL is invalid")
        }

        self = url
    }

    /// The URL of the primary app group container.
    static var appGroupContainerDirectory: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: InfoPlistReader.main.appGroupIdentifier) else {
            MXLog.error("Application Group unavailable, falling back to the application folder")
            // Browserstack doesn't properly handle AppGroup entitlements so this fails, presumably because of the resigning happening on their side
            // Try using the normal app folder instead of the app group
            // https://www.browserstack.com/docs/app-automate/appium/troubleshooting/entitlements-error
            
            return URL.applicationSupportDirectory.deletingLastPathComponent().deletingLastPathComponent()
        }
        
        return url
    }

    /// The base directory where all session data is stored.
    static var sessionsBaseDirectory: URL {
        let applicationSupportSessionsURL = applicationSupportBaseDirectory.appendingPathComponent("Sessions", isDirectory: true)
        
        try? FileManager.default.createDirectoryIfNeeded(at: applicationSupportSessionsURL)

        return applicationSupportSessionsURL
    }
    
    /// The base directory where all application support data is stored.
    static var applicationSupportBaseDirectory: URL {
        var url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(InfoPlistReader.main.baseBundleIdentifier, isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            MXLog.error("Failed excluding Application Support from backups")
        }

        return url
    }
    
    /// The base directory where all application support data is stored.
    static var cachesBaseDirectory: URL {
        let url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
            .appendingPathComponent(InfoPlistReader.main.baseBundleIdentifier, isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        // Caches are excluded from backups automatically anyway.
        // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

        return url
    }
    
    var globalProxy: String? {
        if let proxySettingsUnmanaged = CFNetworkCopySystemProxySettings() {
            let proxySettings = proxySettingsUnmanaged.takeRetainedValue()
            let proxiesUnmanaged = CFNetworkCopyProxiesForURL(self as CFURL, proxySettings)
            if let proxy = (proxiesUnmanaged.takeRetainedValue() as? [[AnyHashable: Any]])?.first,
               let hostname = proxy[kCFProxyHostNameKey] as? String,
               let port = proxy[kCFProxyPortNumberKey] as? Int {
                return "\(hostname):\(port)"
            }
        }
        return nil
    }
}
