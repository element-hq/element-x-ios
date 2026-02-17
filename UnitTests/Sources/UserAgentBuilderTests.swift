//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct UserAgentBuilderTests {
    @Test
    func isNotUnknow() {
        #expect(UserAgentBuilder.makeASCIIUserAgent() != "unknown")
    }
    
    @Test
    func containsClientName() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        #expect(userAgent.contains(InfoPlistReader.main.bundleDisplayName) == true, "\(userAgent) does not contain client name")
    }
    
    @Test
    func containsClientVersion() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        #expect(userAgent.contains(InfoPlistReader.main.bundleShortVersionString) == true, "\(userAgent) does not contain client version")
    }
}
