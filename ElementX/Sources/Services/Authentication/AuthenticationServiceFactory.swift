//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// sourcery: AutoMockable
protocol AuthenticationServiceFactoryProtocol {
    func makeAuthenticationService(userSessionManager: UserSessionManagerProtocol,
                                   encryptionKeyProvider: EncryptionKeyProviderProtocol,
                                   classicAppManager: ClassicAppManagerProtocol?,
                                   appSettings: AppSettings,
                                   appHooks: AppHooks,
                                   targetContext: Target.Context) -> AuthenticationServiceProtocol
}

/// A wrapper around `AuthenticationService` to allow for mocked services to be injected into tests.
struct AuthenticationServiceFactory: AuthenticationServiceFactoryProtocol {
    func makeAuthenticationService(userSessionManager: UserSessionManagerProtocol,
                                   encryptionKeyProvider: EncryptionKeyProviderProtocol,
                                   classicAppManager: ClassicAppManagerProtocol?,
                                   appSettings: AppSettings,
                                   appHooks: AppHooks,
                                   targetContext: Target.Context) -> AuthenticationServiceProtocol {
        AuthenticationService(userSessionManager: userSessionManager,
                              encryptionKeyProvider: encryptionKeyProvider,
                              classicAppManager: classicAppManager,
                              appSettings: appSettings,
                              appHooks: appHooks,
                              targetContext: targetContext)
    }
}
