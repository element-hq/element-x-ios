//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class AppLockTimerTests: XCTestCase {
    var timer: AppLockTimer!
    
    let now = Date.now
    
    var gracePeriod: TimeInterval { timer.gracePeriod }
    var halfGracePeriod: TimeInterval { gracePeriod / 2 }
    var gracePeriodX2: TimeInterval { gracePeriod * 2 }
    var gracePeriodX10: TimeInterval { gracePeriod * 10 }
    
    override func tearDown() {
        timer = nil
    }
    
    func testTimerLockedOnStartup() {
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now),
                      "The app should be locked on a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + 1),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                      "The app should be locked after a fresh launch.")
    }
    
    func testTimerBeforeFirstUnlock() {
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + 1),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                      "The app should always remain locked after backgrounding when locked.")
    }
    
    func testTimerWhenUnlocked() {
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: now + 1),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: now + halfGracePeriod),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriod),
                      "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + gracePeriodX10),
                      "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
    }
    
    func testTimerRepeatingWithinGracePeriod() {
        setupTimer(unlocked: true, backgroundedAt: now)
        
        var nextCheck = now + halfGracePeriod
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: nextCheck),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod + halfGracePeriod
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX2
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX10
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: nextCheck),
                      "The app should become locked however when finally staying backgrounded for longer than the grace period.")
    }
    
    func testTimerWithLongForeground() {
        setupTimer(unlocked: true)
        
        let backgroundDate = now + gracePeriodX10
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: backgroundDate + 1),
                       "The grace period should be measured from the time the app was backgrounded, and not when it was unlocked.")
    }
    
    func testChangingTimeLocksApp() {
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now - 1),
                      "The the device's clock is changed to before the app was backgrounded, the device should remain locked.")
    }
    
    func testNoGracePeriod() {
        // Given a timer with no grace period that is in the background.
        setupTimer(gracePeriod: 0, unlocked: true)
        let backgroundDate = now + 1
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        // Then the app should be locked immediately.
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: backgroundDate))
    }
    
    func testResignActive() {
        // Given a timer with no grace period.
        setupTimer(gracePeriod: 0, unlocked: true)
        
        // When entering the background.
        timer.applicationDidEnterBackground(date: now)
        
        // Then the app should be locked.
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + 1))
        
        // When the app resigns active but doesn't enter the background.
        // (Nothing to do here, we just don't call applicationDidEnterBackground).
        
        // Then the app should also remain locked.
        XCTAssertTrue(timer.computeLockState(didBecomeActiveAt: now + 2))
        
        // When unlocking the app and resigning active (but not entering the background)
        timer.registerUnlock()
        // (Again, nothing to do here for resigning active)
        
        // Then the app should not become locked.
        XCTAssertFalse(timer.computeLockState(didBecomeActiveAt: now + 3))
    }
    
    // MARK: - Helpers
    
    /// Sets up the timer for testing.
    /// - Parameters:
    ///   - gracePeriod: Set up the test with a custom grace period for the timer. Defaults to 3 minutes.
    ///   - unlocked: Whether the timer should consider itself unlocked or not.
    ///   - backgroundedDate: If not nil, the timer will consider the app to have been backgrounded at the specified date.
    private func setupTimer(gracePeriod: TimeInterval = 180, unlocked: Bool, backgroundedAt backgroundedDate: Date? = nil) {
        timer = AppLockTimer(gracePeriod: gracePeriod)
        if unlocked {
            timer.registerUnlock()
        }
        if let backgroundedDate {
            timer.applicationDidEnterBackground(date: backgroundedDate)
        }
    }
}
