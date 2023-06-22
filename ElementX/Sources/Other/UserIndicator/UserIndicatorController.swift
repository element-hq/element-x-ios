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

import SwiftUI

class UserIndicatorController: ObservableObject, UserIndicatorControllerProtocol, CustomStringConvertible {
    private let rootCoordinator: CoordinatorProtocol
    
    private var dismisalTimer: Timer?
    private var displayTimes = [String: Date]()
    private var delayedIndicators = [String: Bool]()
    
    var nonPersistentDisplayDuration = 2.5
    var minimumDisplayDuration = 0.5
    
    @Published private(set) var activeIndicator: UserIndicator?
    private(set) var indicatorQueue = [UserIndicator]() {
        didSet {
            activeIndicator = indicatorQueue.last
            
            if let activeIndicator, !activeIndicator.persistent {
                dismisalTimer?.invalidate()
                dismisalTimer = Timer.scheduledTimer(withTimeInterval: nonPersistentDisplayDuration, repeats: false) { [weak self] _ in
                    self?.retractIndicatorWithId(activeIndicator.id)
                }
            }
        }
    }
    
    @Published var alertInfo: AlertInfo<UUID>?
    
    init(rootCoordinator: CoordinatorProtocol) {
        self.rootCoordinator = rootCoordinator
    }
        
    func toPresentable() -> AnyView {
        AnyView(
            UserIndicatorPresenter(userIndicatorController: self, rootView: rootCoordinator.toPresentable())
        )
    }
    
    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        if let index = indicatorQueue.firstIndex(where: { $0.id == indicator.id }) {
            indicatorQueue[index] = indicator
        } else {
            if let delay {
                delayedIndicators[indicator.id] = true
                Timer.scheduledTimer(withTimeInterval: Double(delay.components.seconds), repeats: false) { [weak self] _ in
                    guard let self else { return }
                    
                    guard delayedIndicators[indicator.id] == true else {
                        return
                    }
                    
                    retractIndicatorWithId(indicator.id)
                    indicatorQueue.append(indicator)
                    delayedIndicators[indicator.id] = nil
                }
            } else {
                retractIndicatorWithId(indicator.id)
                indicatorQueue.append(indicator)
            }
        }
        
        displayTimes[indicator.id] = .now
    }
    
    func retractAllIndicators() {
        for indicator in indicatorQueue {
            retractIndicatorWithId(indicator.id)
        }
    }
    
    func retractIndicatorWithId(_ id: String) {
        delayedIndicators[id] = nil
        
        guard let displayTime = displayTimes[id], abs(displayTime.timeIntervalSinceNow) <= minimumDisplayDuration else {
            indicatorQueue.removeAll { $0.id == id }
            return
        }
    
        Timer.scheduledTimer(withTimeInterval: minimumDisplayDuration, repeats: false) { [weak self] _ in
            self?.indicatorQueue.removeAll { $0.id == id }
            self?.displayTimes[id] = nil
        }
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        "UserIndicatorController(\(String(describing: rootCoordinator)))"
    }
}
