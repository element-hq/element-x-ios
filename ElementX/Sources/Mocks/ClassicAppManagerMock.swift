//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension ClassicAppManagerMock {
    struct Configuration { }
    
    convenience init(_ configuration: Configuration) {
        self.init()
    }
}

extension ClassicAppAccount {
    static var mockAlice: ClassicAppAccount {
        ClassicAppAccount(userID: "@alice:matrix.org",
                          displayName: "Alice",
                          avatarURL: nil,
                          serverName: "matrix.org",
                          homeserverURL: "https://matrix-client.matrix.org/",
                          cryptoStoreURL: .cachesDirectory,
                          cryptoStorePassphrase: "1234567890",
                          accessToken: "accessToken")
    }
    
    static var mockDan: ClassicAppAccount {
        ClassicAppAccount(userID: "@dan:matrix.org",
                          displayName: "Dan",
                          avatarURL: .mockMXCUserAvatar,
                          serverName: "matrix.org",
                          homeserverURL: "https://matrix-client.matrix.org/",
                          cryptoStoreURL: .cachesDirectory,
                          cryptoStorePassphrase: "1234567890",
                          accessToken: "accessToken")
    }
}
