//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
        queue = DispatchQueue(label: "io.element.elementx.network_monitor", qos: .background)
        pathMonitor = NWPathMonitor()
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    MXLog.info("Network reachability changed to reachable")
                    self?.reachabilitySubject.send(.reachable)
                } else {
                    MXLog.info("Network reachability changed to unreachable")
                    self?.reachabilitySubject.send(.unreachable)
                }
            }
        }
        pathMonitor.start(queue: queue)
    }
}
