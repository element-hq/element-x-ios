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
    private var timer: AppLockTimer!
    
    var gracePeriod: TimeInterval {
        timer.gracePeriod
    }
    
    var halfGracePeriod: TimeInterval {
        timer.gracePeriod / 2
    }
    
    var gracePeriodX2: TimeInterval {
        timer.gracePeriod * 2
    }
    
    var gracePeriodX10: TimeInterval {
        timer.gracePeriod * 10
    }
    
    @Test
    mutating func timerLockedOnStartup() {
        setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now),
                "The app should be locked on a fresh launch.")
        
        setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                "The app should be locked after a fresh launch.")
    }
    
    @Test
    mutating func timerBeforeFirstUnlock() {
        setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now),
                "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                "The app should always remain locked after backgrounding when locked.")
    }
    
    @Test
    mutating func timerWhenUnlocked() {
        setupTimer(unlocked: true, backgroundedAt: now)
        #expect(!timer.computeLockState(didBecomeActiveAt: now + 1),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        #expect(!timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
    }
    
    @Test
    mutating func timerRepeatingWithinGracePeriod() {
        setupTimer(unlocked: true, backgroundedAt: now)
        
        var nextCheck = now + halfGracePeriod
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod + halfGracePeriod
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX2
        #expect(!timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX10
        #expect(timer.computeLockState(didBecomeActiveAt: nextCheck),
                "The app should become locked however when finally staying backgrounded for longer than the grace period.")
    }
    
    @Test
    mutating func timerWithLongForeground() {
        setupTimer(unlocked: true)
        
        let backgroundDate = now + gracePeriodX10
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        #expect(!timer.computeLockState(didBecomeActiveAt: backgroundDate + 1),
                "The grace period should be measured from the time the app was backgrounded, and not when it was unlocked.")
    }
    
    @Test
    mutating func changingTimeLocksApp() {
        setupTimer(unlocked: true, backgroundedAt: now)
        #expect(timer.computeLockState(didBecomeActiveAt: now - 1),
                "The the device's clock is changed to before the app was backgrounded, the device should remain locked.")
    }
    
    @Test
    mutating func noGracePeriod() {
        // Given a timer with no grace period that is in the background.
        setupTimer(gracePeriod: 0, unlocked: true)
        let backgroundDate = now + 1
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        // Then the app should be locked immediately.
        #expect(timer.computeLockState(didBecomeActiveAt: backgroundDate))
    }
    
    @Test
    mutating func resignActive() {
        // Given a timer with no grace period.
        setupTimer(gracePeriod: 0, unlocked: true)
        
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
    
    private mutating func setupTimer(gracePeriod: TimeInterval = 180, unlocked: Bool, backgroundedAt backgroundedDate: Date? = nil) {
        let timer = AppLockTimer(gracePeriod: gracePeriod)
        if unlocked {
            timer.registerUnlock()
        }
        if let backgroundedDate {
            timer.applicationDidEnterBackground(date: backgroundedDate)
        }
        self.timer = timer
    }
}
