//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// A timer that adds a grace-period to the app before locking it.
class AppLockTimer {
    /// The amount of time the app should remain unlocked for whilst backgrounded.
    let gracePeriod: TimeInterval
    
    /// Whether the timer considers the app to be locked or not. Always starts with a locked app.
    ///
    /// Internally this value may be incorrect, always call `needsUnlock` to get the correct value.
    private var isLocked = true
    /// The date when the app was last backgrounded whilst in an unlocked state.
    private var lastUnlockedBackground: Date?
    
    /// Whether or not the app has moved to the background.
    ///
    /// This allows us to distinguish between `willResignActive` and `didEnterBackground`.
    private var isInBackground = false
    
    /// Creates a new timer.
    /// - Parameter gracePeriod: The amount of time the app should remain unlocked for whilst backgrounded.
    init(gracePeriod: TimeInterval) {
        self.gracePeriod = gracePeriod
    }
    
    /// Signals to the timer to track how long the app will be backgrounded for.
    func applicationDidEnterBackground(date: Date = .now) {
        isInBackground = true
        // Only update the last background date if the app is currently unlocked.
        guard !isLocked else { return }
        lastUnlockedBackground = date
    }
    
    /// Asks the timer to recompute the lock state when active. If ``applicationDidEnterBackground`` hasn't been
    /// called since the last computation, then this method won't recompute it, instead directly returning the previous state.
    func computeLockState(didBecomeActiveAt date: Date) -> Bool {
        guard isInBackground else { return isLocked }
        isInBackground = false
        
        guard !isLocked, let lastUnlockedBackground else { return true }
        
        isLocked = date.timeIntervalSince(lastUnlockedBackground) >= gracePeriod
        
        // Don't allow changing the device's clock to unlock the app.
        if date < lastUnlockedBackground {
            isLocked = true
        }
        
        return isLocked
    }
    
    /// Registers a successful unlock with the timer.
    func registerUnlock() {
        isLocked = false
    }
}
