//
// Copyright 2023 New Vector Ltd
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
