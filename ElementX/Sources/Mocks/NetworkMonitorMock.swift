//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

extension NetworkMonitorMock {
    struct Configuration {
        var reachabilityPublisher = CurrentValuePublisher<NetworkMonitorReachability, Never>(.init(.reachable))
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        underlyingReachabilityPublisher = configuration.reachabilityPublisher
    }
}
