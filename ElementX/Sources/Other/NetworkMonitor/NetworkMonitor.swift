//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import Network

class NetworkMonitor: NetworkMonitorProtocol {
    private let pathMonitor: NWPathMonitor
    private let queue: DispatchQueue
    
    private let reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        reachabilitySubject.asCurrentValuePublisher()
    }
    
    init() {
        queue = DispatchQueue(label: "io.element.elementx.networkmonitor", qos: .background)
        pathMonitor = NWPathMonitor()
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.reachabilitySubject.send(.reachable)
                } else {
                    self?.reachabilitySubject.send(.unreachable)
                }
            }
        }
        pathMonitor.start(queue: queue)
    }
}
