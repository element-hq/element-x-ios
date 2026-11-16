//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

extension AuthenticationServiceFactoryMock {
    struct Configuration { }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        makeAuthenticationServiceUserSessionManagerEncryptionKeyProviderClassicAppManagerAppSettingsAppHooksTargetContextReturnValue = AuthenticationService.mock
    }
}
