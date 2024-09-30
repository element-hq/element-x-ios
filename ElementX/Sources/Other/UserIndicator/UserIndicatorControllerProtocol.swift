//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

// sourcery: AutoMockable
protocol UserIndicatorControllerProtocol: CoordinatorProtocol {
    func submitIndicator(_ indicator: UserIndicator, delay: Duration?)
    func retractIndicatorWithId(_ id: String)
    func retractAllIndicators()
    
    var window: UIWindow? { get set }
    var alertInfo: AlertInfo<UUID>? { get set }
}

extension UserIndicatorControllerProtocol {
    func submitIndicator(_ indicator: UserIndicator) {
        submitIndicator(indicator, delay: nil)
    }
}
