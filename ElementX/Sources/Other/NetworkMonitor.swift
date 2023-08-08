//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import Network

enum NetworkMonitorReachability {
    case reachable
    case unreachable
}

class NetworkMonitor {
    private let pathMonitor: NWPathMonitor
    private let queue: DispatchQueue
    
    private let reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        reachabilitySubject.asCurrentValuePublisher()
    }
    
    var isCurrentConnectionExpensive: Bool {
        pathMonitor.currentPath.isExpensive
    }
    
    var isCurrentConnectionConstrained: Bool {
        pathMonitor.currentPath.isConstrained
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
