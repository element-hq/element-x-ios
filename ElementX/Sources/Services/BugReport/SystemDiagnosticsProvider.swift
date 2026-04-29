//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct SystemDiagnosticsProvider: DiagnosticsProviding {
    struct Context {
        let appDisplayName: String
        let appVersion: String
        let buildNumber: String
        let bundleIdentifier: String
        let operatingSystem: String
        let userAgent: String
        let resolvedLanguages: [String]
        let preferredLanguages: [String]
        let timeZoneIdentifier: String
        let userID: String?
        let deviceID: String?
        
        static func live(userID: String?, deviceID: String?) -> Self {
            .init(appDisplayName: InfoPlistReader.main.bundleDisplayName,
                  appVersion: InfoPlistReader.main.bundleShortVersionString,
                  buildNumber: InfoPlistReader.main.bundleVersion,
                  bundleIdentifier: InfoPlistReader.main.bundleIdentifier,
                  operatingSystem: SystemDiagnosticsProvider.operatingSystemDescription(),
                  userAgent: UserAgentBuilder.makeASCIIUserAgent(),
                  resolvedLanguages: Bundle.app.preferredLocalizations,
                  preferredLanguages: Locale.preferredLanguages,
                  timeZoneIdentifier: TimeZone.current.identifier,
                  userID: userID,
                  deviceID: deviceID)
        }
    }
    
    private let context: Context
    private let redactor: any Redacting
    private let dateProvider: () -> Date
    
    init(context: Context,
         redactor: any Redacting = Redactor(),
         dateProvider: @escaping () -> Date = Date.init) {
        self.context = context
        self.redactor = redactor
        self.dateProvider = dateProvider
    }
    
    init(userID: String?,
         deviceID: String?,
         redactor: any Redacting = Redactor(),
         dateProvider: @escaping () -> Date = Date.init) {
        self.init(context: .live(userID: userID, deviceID: deviceID),
                  redactor: redactor,
                  dateProvider: dateProvider)
    }
    
    func makeDiagnostics() async throws -> String {
        try Task.checkCancellation()
        await Task.yield()
        
        var lines = [
            "App: \(context.appDisplayName)",
            "Version: \(context.appVersion) (\(context.buildNumber))",
            "Bundle ID: \(context.bundleIdentifier)",
            "OS: \(context.operatingSystem)",
            "User Agent: \(context.userAgent)",
            "Resolved Languages: \(context.resolvedLanguages.joined(separator: ", "))",
            "Preferred Languages: \(context.preferredLanguages.joined(separator: ", "))",
            "Time Zone: \(context.timeZoneIdentifier)",
            "Generated: \(Self.timestampFormatter.string(from: dateProvider()))"
        ]
        
        if let userID = context.userID {
            lines.append("User ID: \(userID)")
        }
        
        if let deviceID = context.deviceID {
            lines.append("Device ID: \(deviceID)")
        }
        
        try Task.checkCancellation()
        return redactor.redact(lines.joined(separator: "\n"))
    }
    
    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static func operatingSystemDescription() -> String {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        } else {
            return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        }
    }
}
