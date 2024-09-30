//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

extension NetworkMonitorMock {
    static var `default`: NetworkMonitorMock {
        let mock = NetworkMonitorMock()
        mock.underlyingReachabilityPublisher = .init(.init(.reachable))
        return mock
    }
}
