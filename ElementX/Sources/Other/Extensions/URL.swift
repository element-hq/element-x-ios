//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Custom URLs

extension URL {
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
    
    static var appGroupLogsDirectory: URL {
        appGroupContainerDirectory
            .appending(component: "Library", directoryHint: .isDirectory)
            .appending(component: "Logs", directoryHint: .isDirectory)
            .appending(component: InfoPlistReader.main.baseBundleIdentifier, directoryHint: .isDirectory)
    }

    /// The base directory where all session data is stored.
    static var sessionsBaseDirectory: URL {
        let applicationSupportSessionsURL = applicationSupportBaseDirectory.appending(component: "Sessions", directoryHint: .isDirectory)
        
        try? FileManager.default.createDirectoryIfNeeded(at: applicationSupportSessionsURL)

        return applicationSupportSessionsURL
    }
    
    /// The base directory where all application support data is stored.
    static var applicationSupportBaseDirectory: URL {
        var url = appGroupContainerDirectory
            .appending(component: "Library", directoryHint: .isDirectory)
            .appending(component: "Application Support", directoryHint: .isDirectory)
            .appending(component: InfoPlistReader.main.baseBundleIdentifier, directoryHint: .isDirectory)

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
            .appending(component: "Library", directoryHint: .isDirectory)
            .appending(component: "Caches", directoryHint: .isDirectory)
            .appending(component: InfoPlistReader.main.baseBundleIdentifier, directoryHint: .isDirectory)
            .appending(component: "Sessions", directoryHint: .isDirectory)

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
            .appending(component: "tmp", directoryHint: .isDirectory)

        try? FileManager.default.createDirectoryIfNeeded(at: url)
        
        // Temporary files are excluded from backups automatically.
        // https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

        return url
    }
    
    var globalProxy: String? {
        let span = MXLog.createSpan("Global proxy")
        span.enter()
        defer {
            span.exit()
        }
        
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else {
            MXLog.error("Failed retrieving proxy settings")
            return nil
        }
        
        let proxies = CFNetworkCopyProxiesForURL(self as CFURL, proxySettings).takeRetainedValue() as? [[CFString: Any]]
        
        guard let firstProxy = proxies?.first,
              let proxyType = firstProxy[kCFProxyTypeKey] as? String,
              proxyType != kCFProxyTypeNone as String else {
            MXLog.info("No global proxy configured.")
            return nil
        }
        
        MXLog.info("Found \(String(describing: proxies?.count)) proxies, using the first one.")
        MXLog.info("Proxy type is \(proxyType)")
            
        guard let host = firstProxy[kCFProxyHostNameKey] as? String else {
            MXLog.error("Found proxy with invalid host name")
            return nil
        }
        
        let port = firstProxy[kCFProxyPortNumberKey] as? Int
        
        MXLog.info("Found proxy host: \(host), port: \(String(describing: port))")
        
        if let port {
            return "\(host):\(port)"
        } else {
            return host
        }
    }
    
    // MARK: Mocks
    
    static var mockMXCAudio: URL {
        "mxc://matrix.org/1234567890AuDiO"
    }

    static var mockMXCFile: URL {
        "mxc://matrix.org/1234567890FiLe"
    }

    static var mockMXCImage: URL {
        "mxc://matrix.org/1234567890ImAgE"
    }

    static var mockMXCVideo: URL {
        "mxc://matrix.org/1234567890ViDeO"
    }

    static var mockMXCAvatar: URL {
        "mxc://matrix.org/1234567890AvAtAr"
    }

    static var mockMXCUserAvatar: URL {
        "mxc://matrix.org/1234567890AvAtArUsEr"
    }
}

// MARK: - Helpers

extension URL: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        guard let url = URL(string: "\(value)") else {
            fatalError("The static string used to create this URL is invalid")
        }
        
        self = url
    }
    
    /// Sanitises the URL for use as the name of a directory.
    func asDirectoryName() -> String {
        absoluteString.asURLDirectoryName()
    }
}

extension String {
    /// Assumes that the string is a URL and sanitises it for use as the name of a directory.
    func asURLDirectoryName() -> String {
        replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacing(/[:\/\p{C}]/, with: "-")
    }
}

// MARK: - Phishing Confirmation URL

extension URL {
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
