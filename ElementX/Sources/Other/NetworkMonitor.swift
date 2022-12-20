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

class NetworkMonitor {
    private let pathMonitor: NWPathMonitor
    private let queue: DispatchQueue
    let reachabilityPublisher: CurrentValueSubject<Bool, Never>
    
    var isCurrentConnectionExpensive: Bool {
        pathMonitor.currentPath.isExpensive
    }
    
    var isCurrentConnectionConstrained: Bool {
        pathMonitor.currentPath.isConstrained
    }
    
    init() {
        queue = DispatchQueue(label: "io.element.elementx.networkmonitor")
        pathMonitor = NWPathMonitor()
        reachabilityPublisher = CurrentValueSubject<Bool, Never>(pathMonitor.currentPath.status == .satisfied)
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.reachabilityPublisher.send(true)
                } else {
                    self?.reachabilityPublisher.send(false)
                }
            }
        }
        pathMonitor.start(queue: queue)
    }
}
