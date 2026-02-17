//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct AppLockTimerTests {
    private let now = Date.now
    
    private func gracePeriod(for timer: AppLockTimer) -> TimeInterval {
        timer.gracePeriod
    }
    
    private func halfGracePeriod(for timer: AppLockTimer) -> TimeInterval {
        timer.gracePeriod / 2
    }
    
    private func gracePeriodX2(for timer: AppLockTimer) -> TimeInterval {
        timer.gracePeriod * 2
    }
    
    private func gracePeriodX10(for timer: AppLockTimer) -> TimeInterval {
        timer.gracePeriod * 10
    }
    
    @Test
    func timerLockedOnStartup() {
        var timer = setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now),
                "The app should be locked on a fresh launch.")
        
        timer = setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should be locked after a fresh launch.")
        
        timer = setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod(for: timer)),
                "The app should be locked after a fresh launch.")
        
        timer = setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod(for: timer)),
                "The app should be locked after a fresh launch.")
        
        timer = setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10(for: timer)),
                "The app should be locked after a fresh launch.")
    }
    
    @Test
    func timerBeforeFirstUnlock() {
        var timer = setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now),
                "The app should always remain locked after backgrounding when locked.")
        
        timer = setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should always remain locked after backgrounding when locked.")
        
        timer = setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod(for: timer)),
                "The app should always remain locked after backgrounding when locked.")
        
        timer = setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod(for: timer)),
                "The app should always remain locked after backgrounding when locked.")
        
        timer = setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10(for: timer)),
                "The app should always remain locked after backgrounding when locked.")
    }
    
    @Test
    func timerWhenUnlocked() {
        var timer = setupTimer(unlocked: true, backgroundedAt: now)
        #expect(!timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        timer = setupTimer(unlocked: true, backgroundedAt: now)
        #expect(!timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod(for: timer)),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        timer = setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod(for: timer)),
                "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
        
        timer = setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10(for: timer)),
                "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
    }
    
    @Test
    func timerRepeatingWithinGracePeriod() {
        var timer = setupTimer(unlocked: true, backgroundedAt: now)
        
        var nextCheck = now + halfGracePeriod(for: timer)
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod(for: timer)
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod(for: timer) + halfGracePeriod(for: timer)
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX2(for: timer)
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX10(for: timer)
        #expect(timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should become locked however when finally staying backgrounded for longer than the grace period.")
    }
    
    @Test
    func timerWithLongForeground() {
        var timer = setupTimer(unlocked: true)
        
        let backgroundDate = now + gracePeriodX10(for: timer)
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        #expect(!timer.computeLockState(didBecomeActiveAt: backgroundDate + 1),
                "The grace period should be measured from the time the app was backgrounded, and not when it was unlocked.")
    }
    
    @Test
    func changingTimeLocksApp() {
        var timer = setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now - 1),
                "The the device's clock is changed to before the app was backgrounded, the device should remain locked.")
    }
    
    @Test
    func noGracePeriod() {
        // Given a timer with no grace period that is in the background.
        var timer = setupTimer(gracePeriod: 0, unlocked: true)
        let backgroundDate = now + 1
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        // Then the app should be locked immediately.
        #expect(timer.computeLockState(didBecomeActiveAt: backgroundDate))
    }
    
    @Test
    func resignActive() {
        // Given a timer with no grace period.
        var timer = setupTimer(gracePeriod: 0, unlocked: true)
        
        // When entering the background.
        timer.applicationDidEnterBackground(date: now)
        
        // Then the app should be locked.
        #expect(timer.computeLockState(didBecomeActiveAt: now + 1))
        
        // When the app resigns active but doesn't enter the background.
        // (Nothing to do here, we just don't call applicationDidEnterBackground).
        
        // Then the app should also remain locked.
        #expect(timer.computeLockState(didBecomeActiveAt: now + 2))
        
        // When unlocking the app and resigning active (but not entering the background)
        timer.registerUnlock()
        // (Again, nothing to do here for resigning active)
        
        // Then the app should not become locked.
        #expect(!timer.computeLockState(didBecomeActiveAt: now + 3))
    }
    
    // MARK: - Helpers
    
    private func setupTimer(gracePeriod: TimeInterval = 180, unlocked: Bool, backgroundedAt backgroundedDate: Date? = nil) -> AppLockTimer {
        var timer = AppLockTimer(gracePeriod: gracePeriod)
        if unlocked {
            timer.registerUnlock()
        }
        if let backgroundedDate {
            timer.applicationDidEnterBackground(date: backgroundedDate)
        }
        return timer
    }
}
