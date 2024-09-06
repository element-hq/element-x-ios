//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class UserIndicatorController: ObservableObject, UserIndicatorControllerProtocol {
    private var dismissalTimer: Timer?
    private var displayTimes = [String: Date]()
    private var delayedIndicators = Set<String>()
    
    var nonPersistentDisplayDuration = 2.5
    var minimumDisplayDuration = 0.5
    
    @Published private(set) var activeIndicator: UserIndicator?
    private(set) var indicatorQueue = [UserIndicator]() {
        didSet {
            activeIndicator = indicatorQueue.last
            
            if let activeIndicator, !activeIndicator.persistent {
                dismissalTimer?.invalidate()
                dismissalTimer = Timer.scheduledTimer(withTimeInterval: nonPersistentDisplayDuration, repeats: false) { [weak self] _ in
                    self?.retractIndicatorWithId(activeIndicator.id)
                }
            }
        }
    }
    
    @Published var alertInfo: AlertInfo<UUID>?
    
    var window: UIWindow? {
        didSet {
            let hostingController = UIHostingController(rootView: UserIndicatorPresenter(userIndicatorController: self).statusBarHidden(ProcessInfo.isRunningUITests))
            hostingController.view.backgroundColor = .clear
            window?.rootViewController = hostingController
        }
    }
    
    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        if let index = indicatorQueue.firstIndex(where: { $0.id == indicator.id }) {
            indicatorQueue[index] = indicator
            displayTimes[indicator.id] = .now
        } else {
            if let delay {
                delayedIndicators.insert(indicator.id)

                Timer.scheduledTimer(withTimeInterval: delay.seconds, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    
                    guard delayedIndicators.contains(indicator.id) else {
                        return
                    }

                    enqueue(indicator: indicator)
                }
            } else {
                enqueue(indicator: indicator)
            }
        }
    }
    
    func retractAllIndicators() {
        for indicator in indicatorQueue {
            retractIndicatorWithId(indicator.id)
        }
    }
    
    func retractIndicatorWithId(_ id: String) {
        delayedIndicators.remove(id)
        
        guard let displayTime = displayTimes[id], abs(displayTime.timeIntervalSinceNow) <= minimumDisplayDuration else {
            indicatorQueue.removeAll { $0.id == id }
            return
        }
    
        Timer.scheduledTimer(withTimeInterval: minimumDisplayDuration, repeats: false) { [weak self] _ in
            self?.indicatorQueue.removeAll { $0.id == id }
            self?.displayTimes[id] = nil
        }
    }
    
    // MARK: - Private

    private func enqueue(indicator: UserIndicator) {
        retractIndicatorWithId(indicator.id)
        indicatorQueue.append(indicator)
        displayTimes[indicator.id] = .now
    }
}
