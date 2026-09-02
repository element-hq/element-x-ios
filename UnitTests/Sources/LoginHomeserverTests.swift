//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct LoginHomeserverTests {
    @Test
    func sanitize() {
        // Lowercased, whitespace trimmed, https:// dropped and trailing slashes removed.
        #expect(LoginHomeserver(serverNameOrBaseURL: "Matrix.org", loginMode: .unknown).serverNameOrBaseURL == "matrix.org")
        #expect(LoginHomeserver(serverNameOrBaseURL: "  matrix.org  ", loginMode: .unknown).serverNameOrBaseURL == "matrix.org")
        #expect(LoginHomeserver(serverNameOrBaseURL: "https://matrix.org", loginMode: .unknown).serverNameOrBaseURL == "matrix.org")
        #expect(LoginHomeserver(serverNameOrBaseURL: "https://matrix.org/", loginMode: .unknown).serverNameOrBaseURL == "matrix.org")
        #expect(LoginHomeserver(serverNameOrBaseURL: "HTTPS://Matrix.org///", loginMode: .unknown).serverNameOrBaseURL == "matrix.org")
    }
    
    @Test
    func sanitizationKeepsHTTPScheme() {
        #expect(LoginHomeserver(serverNameOrBaseURL: "http://localhost:8008", loginMode: .unknown).serverNameOrBaseURL == "http://localhost:8008",
                "The http:// scheme should be preserved as an indicator")
    }
}
