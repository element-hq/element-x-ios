//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum NetworkMonitorReachability {
    case reachable
    case unreachable
}

protocol NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> { get }
}

// sourcery: AutoMockable
extension NetworkMonitorProtocol { }
