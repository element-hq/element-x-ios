//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum NetworkMonitorReachability {
    case reachable
    case unreachable
}

enum HomeserverReachability {
    /// The store is open and the homeserver is reachable.
    case reachable
    /// The homeserver can't be reached even though we're trying to sync (i.e. offline).
    case unreachable
    /// The client is suspended, so the store is closed and we're not trying to reach the homeserver.
    case suspended
    
    init(_ reachability: NetworkMonitorReachability) {
        self = reachability == .reachable ? .reachable : .unreachable
    }
}

protocol NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> { get }
}

// sourcery: AutoMockable
extension NetworkMonitorProtocol { }
