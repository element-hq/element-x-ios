//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK

/// Adds the missing methods for conformance to the protocol.
extension KeychainControllerMock {
    func retrieveSessionFromKeychain(userId: String) throws -> Session { fatalError("Not implemented") }
    func saveSessionInKeychain(session: Session) { fatalError("Not implemented") }
}
