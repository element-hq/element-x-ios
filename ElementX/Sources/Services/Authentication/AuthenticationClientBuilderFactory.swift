//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol AuthenticationClientBuilderFactoryProtocol {
    func makeBuilder(sessionDirectories: SessionDirectories,
                     passphrase: String,
                     clientSessionDelegate: ClientSessionDelegate,
                     appSettings: AppSettings,
                     appHooks: AppHooks) -> AuthenticationClientBuilderProtocol
}

/// A wrapper around `ClientBuilder` to share reusable code between Normal and QR logins.
struct AuthenticationClientBuilderFactory: AuthenticationClientBuilderFactoryProtocol {
    func makeBuilder(sessionDirectories: SessionDirectories,
                     passphrase: String,
                     clientSessionDelegate: ClientSessionDelegate,
                     appSettings: AppSettings,
                     appHooks: AppHooks) -> AuthenticationClientBuilderProtocol {
        AuthenticationClientBuilder(sessionDirectories: sessionDirectories,
                                    passphrase: passphrase,
                                    clientSessionDelegate: clientSessionDelegate,
                                    appSettings: appSettings,
                                    appHooks: appHooks)
    }
}
