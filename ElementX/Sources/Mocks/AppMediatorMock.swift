//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

extension AppMediatorMock {
    struct Configuration {
        var appState = UIApplication.State.active
        var isCameraAuthorized = true
        var networkMonitor = NetworkMonitorMock(.init())
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        underlyingAppState = configuration.appState
        requestAuthorizationIfNeededUnderlyingReturnValue = configuration.isCameraAuthorized
        underlyingNetworkMonitor = configuration.networkMonitor
        
        let windowManagerMock = WindowManagerMock()
        windowManagerMock.closeAllSecondaryWindowsClosure = { }
        windowManagerMock.closeSecondaryWindowForTypeClosure = { _ in }
        underlyingWindowManager = windowManagerMock
    }
}
