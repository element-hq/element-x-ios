//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension URL: @retroactive ExpressibleByStringLiteral {
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
    static var sessionCachesBaseDirectory: URL {
        let url = appGroupContainerDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
            .appendingPathComponent(InfoPlistReader.main.baseBundleIdentifier, isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        // Caches are excluded from backups automatically.
        // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

        return url
    }
    
    /// The app group temporary directory (useful for transferring files between different bundles).
    ///
    /// **Note:** This `tmp` directory doesn't appear to behave as expected as it isn't being tidied up by the system.
    /// Make sure to manually tidy up any files you place in here once you've transferred them from one bundle to another.
    static var appGroupTemporaryDirectory: URL {
        let url = appGroupContainerDirectory
            .appendingPathComponent("tmp", isDirectory: true)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        // Temporary files are excluded from backups automatically.
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
    
    static let confirmationScheme = "confirm"
    
    var requiresConfirmation: Bool {
        scheme == Self.confirmationScheme
    }
    
    var confirmationParameters: ConfirmURLParameters? {
        guard requiresConfirmation,
              let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: true)?.queryItems else {
            return nil
        }
        return ConfirmURLParameters(queryItems: queryItems)
    }
    
    // MARK: Mocks
    
    static var mockMXCAudio: URL { "mxc://matrix.org/1234567890AuDiO" }
    static var mockMXCFile: URL { "mxc://matrix.org/1234567890FiLe" }
    static var mockMXCImage: URL { "mxc://matrix.org/1234567890ImAgE" }
    static var mockMXCVideo: URL { "mxc://matrix.org/1234567890ViDeO" }
    static var mockMXCAvatar: URL { "mxc://matrix.org/1234567890AvAtAr" }
    static var mockMXCUserAvatar: URL { "mxc://matrix.org/1234567890AvAtArUsEr" }
}

struct ConfirmURLParameters {
    static let internalURLKey = "internalURL"
    static let displayStringKey = "displayString"
    
    let internalURL: URL
    let displayString: String
    
    var urlQueryItems: [URLQueryItem] {
        [URLQueryItem(name: Self.internalURLKey, value: internalURL.absoluteString),
         URLQueryItem(name: Self.displayStringKey, value: displayString)]
    }
}

extension ConfirmURLParameters {
    init?(queryItems: [URLQueryItem]) {
        guard let internalURLString = queryItems.first(where: { $0.name == Self.internalURLKey })?.value,
              let internalURL = URL(string: internalURLString),
              let externalURLString = queryItems.first(where: { $0.name == Self.displayStringKey })?.value else {
            return nil
        }
        displayString = externalURLString
        self.internalURL = internalURL
    }
}
