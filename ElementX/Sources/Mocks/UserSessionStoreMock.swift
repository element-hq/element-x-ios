//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

extension UserSessionStoreMock {
    struct Configuration { }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        userSessionForSessionDirectoriesPassphraseReturnValue = .success(UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))))
        clientSessionDelegate = KeychainControllerMock()
    }
}
