//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

class UserIndicatorController: ObservableObject, UserIndicatorControllerProtocol {
    private var timerCancellable: AnyCancellable?
    private var displayTimes = [String: Date]()
    private var delayedIndicators = Set<String>()
    
    var nonPersistentDisplayDuration = 2.5
    var minimumDisplayDuration = 0.5

    /// Indicators sitting out the remainder of `minimumDisplayDuration` after
    /// being retracted: still visible, but no longer blocking anything.
    @Published private(set) var retractingIndicatorIDs = Set<String>()
    
    @Published private(set) var activeIndicator: UserIndicator? {
        didSet {
            // Never leave the overlay window hit-testable without an indicator on
            // show: its passthrough relies on layer hit-testing (iOS 26), and a
            // just-retracted modal's zero-opacity layers linger until SwiftUI's
            // next cleanup pass - which the user's next tap triggers and loses.
            window?.isUserInteractionEnabled = activeIndicator != nil
        }
    }

    private(set) var indicatorQueue = [UserIndicator]() {
        didSet {
            activeIndicator = indicatorQueue.last
            
            if let activeIndicator, !activeIndicator.persistent {
                timerCancellable?.cancel()
                timerCancellable = Task { [weak self, nonPersistentDisplayDuration] in
                    try await Task.sleep(for: .seconds(nonPersistentDisplayDuration))
                    self?.retractIndicatorWithId(activeIndicator.id)
                }.asCancellable()
            }
        }
    }
    
    var window: UIWindow? {
        didSet {
            let hostingController = UIHostingController(rootView: UserIndicatorPresenter(userIndicatorController: self).statusBarHidden(ProcessInfo.isRunningUITests))
            hostingController.view.backgroundColor = .clear
            window?.rootViewController = hostingController
            window?.isUserInteractionEnabled = activeIndicator != nil
        }
    }
    
    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        if let index = indicatorQueue.firstIndex(where: { $0.id == indicator.id }) {
            indicatorQueue[index] = indicator
            displayTimes[indicator.id] = .now
        } else {
            if let delay {
                delayedIndicators.insert(indicator.id)
                
                Task {
                    try await Task.sleep(for: .seconds(delay.seconds))
                    
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

        // The indicator lingers for the rest of `minimumDisplayDuration` to
        // avoid flashing, but whatever it covered is finished: drop its scrim
        // and stop the overlay window blocking touches straight away
        // (systematically swallowed the first tap after opening a thread).
        retractingIndicatorIDs.insert(id)
        if activeIndicator?.id == id {
            window?.isUserInteractionEnabled = false
        }

        Task {
            try? await Task.sleep(for: .seconds(minimumDisplayDuration))
            indicatorQueue.removeAll { $0.id == id }
            displayTimes[id] = nil
            retractingIndicatorIDs.remove(id)
        }
    }
    
    // MARK: - Private
    
    private func enqueue(indicator: UserIndicator) {
        retractIndicatorWithId(indicator.id)
        retractingIndicatorIDs.remove(indicator.id)
        indicatorQueue.append(indicator)
        displayTimes[indicator.id] = .now
    }
}
