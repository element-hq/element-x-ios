//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AppCoordinatorProtocol: CoordinatorProtocol {
    var windowManager: SecureWindowManagerProtocol { get }
    
    @discardableResult func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool
    
    func handleUserActivity(_ userActivity: NSUserActivity)
}
