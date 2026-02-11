//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

// sourcery: AutoMockable
protocol UserIndicatorControllerProtocol: CoordinatorProtocol {
    func submitIndicator(_ indicator: UserIndicator, delay: Duration?)
    func retractIndicatorWithId(_ id: String)
    func retractAllIndicators()
    
    var window: UIWindow? { get set }
}

extension UserIndicatorControllerProtocol {
    func submitIndicator(_ indicator: UserIndicator) {
        submitIndicator(indicator, delay: nil)
    }
}
