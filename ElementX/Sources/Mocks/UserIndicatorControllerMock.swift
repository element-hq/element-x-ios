//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

extension UserIndicatorControllerMock {
    static var `default`: UserIndicatorControllerMock {
        let mock = UserIndicatorControllerMock()
        mock.submitIndicatorDelayClosure = { _, _ in }
        mock.retractIndicatorWithIdClosure = { _ in }
        mock.retractAllIndicatorsClosure = { }
        return mock
    }
}
