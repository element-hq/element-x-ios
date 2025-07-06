//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

protocol ZeroAuthApiProxyProtocol {
    var authApi: ZeroAuthApiProtocol { get }
    var createAccountApi: ZeroCreateAccountApiProtocol { get }
    var usersApi: ZeroUserApiProtocol { get }
}

class ZeroAuthApiProxy: ZeroAuthApiProxyProtocol {
    let authApi: ZeroAuthApiProtocol
    let createAccountApi: ZeroCreateAccountApiProtocol
    let usersApi: ZeroUserApiProtocol
    
    init(authApi: ZeroAuthApiProtocol,
         createAccountApi: ZeroCreateAccountApiProtocol,
         usersApi: ZeroUserApiProtocol) {
        self.authApi = authApi
        self.createAccountApi = createAccountApi
        self.usersApi = usersApi
    }
}

extension ZeroAuthApiProxy {
    convenience init(appSettings: AppSettings) {
        self.init(authApi: ZeroAuthApi(appSettings: appSettings),
                  createAccountApi: ZeroCreateAccountApi(appSettings: appSettings),
                  usersApi: ZeroUserApi(appSettings: appSettings))
    }
}
