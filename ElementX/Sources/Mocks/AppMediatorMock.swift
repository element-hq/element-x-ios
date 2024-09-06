//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

extension AppMediatorMock {
    static var `default`: AppMediatorMock {
        let mock = AppMediatorMock()
        
        mock.underlyingAppState = .active
        mock.requestAuthorizationIfNeededUnderlyingReturnValue = true
        mock.underlyingWindowManager = WindowManagerMock()
        mock.underlyingNetworkMonitor = NetworkMonitorMock.default
        
        return mock
    }
}
