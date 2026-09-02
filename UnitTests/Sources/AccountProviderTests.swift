//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct AccountProviderTests {
    @Test
    func managedUsesServerNameWhenPresent() {
        let provider = AccountProvider.managed(serverName: "Matrix.org",
                                               baseURL: "https://matrix-client.matrix.org",
                                               canUseServerName: true)
        #expect(provider.serverNameOrBaseURL == "matrix.org")
    }
    
    @Test
    func managedFallsBackToBaseURLWhenShouldNotUserServerName() {
        let provider = AccountProvider.managed(serverName: "Matrix.org",
                                               baseURL: "https://matrix-client.matrix.org",
                                               canUseServerName: false)
        #expect(provider.serverNameOrBaseURL == "matrix-client.matrix.org")
    }
}
