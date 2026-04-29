//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import Foundation

struct SystemDiagnosticsProviderTests {
    @Test
    func makeDiagnosticsFormatsContext() async throws {
        let provider = SystemDiagnosticsProvider(context: .init(appDisplayName: "Element X",
                                                                appVersion: "1.2.3",
                                                                buildNumber: "456",
                                                                bundleIdentifier: "io.element.elementx",
                                                                operatingSystem: "iOS 18.0",
                                                                userAgent: "Element X/1.2.3 (iPhone; iOS 18.0; Scale/3.00)",
                                                                resolvedLanguages: ["en"],
                                                                preferredLanguages: ["en-GB"],
                                                                timeZoneIdentifier: "Europe/London",
                                                                userID: nil,
                                                                deviceID: "ABCDEFG"),
                                               dateProvider: { Date(timeIntervalSince1970: 0) })
        
        let diagnostics = try await provider.makeDiagnostics()
        
        #expect(diagnostics.contains("App: Element X"))
        #expect(diagnostics.contains("Version: 1.2.3 (456)"))
        #expect(diagnostics.contains("Bundle ID: io.element.elementx"))
        #expect(diagnostics.contains("Generated: 1970-01-01T00:00:00.000Z"))
        #expect(diagnostics.contains("Device ID: ABCDEFG"))
    }
    
    @Test
    func makeDiagnosticsRedactsSensitiveValues() async throws {
        let provider = SystemDiagnosticsProvider(context: .init(appDisplayName: "Element X",
                                                                appVersion: "1.2.3",
                                                                buildNumber: "456",
                                                                bundleIdentifier: "io.element.elementx",
                                                                operatingSystem: "iOS 18.0",
                                                                userAgent: "Element X/1.2.3 https://example.com alice@example.com",
                                                                resolvedLanguages: ["en"],
                                                                preferredLanguages: ["en-GB"],
                                                                timeZoneIdentifier: "Europe/London",
                                                                userID: "@alice:example.com",
                                                                deviceID: "ABCDEFG"),
                                               dateProvider: { Date(timeIntervalSince1970: 0) })
        
        let diagnostics = try await provider.makeDiagnostics()
        
        #expect(diagnostics.contains("[redacted url]"))
        #expect(diagnostics.contains("[redacted email]"))
        #expect(diagnostics.contains("[redacted matrix id]"))
        #expect(!diagnostics.contains("https://example.com"))
        #expect(!diagnostics.contains("alice@example.com"))
        #expect(!diagnostics.contains("@alice:example.com"))
    }
}
