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
        XCTAssertTrue(timer.needsUnlock(date: now),
                      "The app should be locked on a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.needsUnlock(date: now + 1),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.needsUnlock(date: now + halfGracePeriod),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriod),
                      "The app should be locked after a fresh launch.")
        
        setupTimer(unlocked: false)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriodX10),
                      "The app should be locked after a fresh launch.")
    }
    
    func testTimerBeforeFirstUnlock() {
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + 1),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + halfGracePeriod),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriod),
                      "The app should always remain locked after backgrounding when locked.")
        
        setupTimer(unlocked: false, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriodX10),
                      "The app should always remain locked after backgrounding when locked.")
    }
    
    func testTimerWhenUnlocked() {
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertFalse(timer.needsUnlock(date: now + 1),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertFalse(timer.needsUnlock(date: now + halfGracePeriod),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriod),
                      "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
        
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now + gracePeriodX10),
                      "The app should become locked when it was unlocked and backgrounded for more than the grace period.")
    }
    
    func testTimerRepeatingWithinGracePeriod() {
        setupTimer(unlocked: true, backgroundedAt: now)
        
        var nextCheck = now + halfGracePeriod
        XCTAssertFalse(timer.needsUnlock(date: nextCheck),
                       "The app should remain unlocked when it was unlocked and backgrounded for less then the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod
        XCTAssertFalse(timer.needsUnlock(date: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriod + halfGracePeriod
        XCTAssertFalse(timer.needsUnlock(date: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX2
        XCTAssertFalse(timer.needsUnlock(date: nextCheck),
                       "The app should remain unlocked when repeating the backgrounded and foreground within the grace period.")
        timer.applicationDidEnterBackground(date: nextCheck)
        
        nextCheck = now + gracePeriodX10
        XCTAssertTrue(timer.needsUnlock(date: nextCheck),
                      "The app should become locked however when finally staying backgrounded for longer than the grace period.")
    }
    
    func testTimerWithLongForeground() {
        setupTimer(unlocked: true)
        
        let backgroundDate = now + gracePeriodX10
        timer.applicationDidEnterBackground(date: backgroundDate)
        
        XCTAssertFalse(timer.needsUnlock(date: backgroundDate + 1),
                       "The grace period should be measured from the time the app was backgrounded, and not when it was unlocked.")
    }
    
    func testChangingTimeLocksApp() {
        setupTimer(unlocked: true, backgroundedAt: now)
        XCTAssertTrue(timer.needsUnlock(date: now - 1),
                      "The the device's clock is changed to before the app was backgrounded, the device should remain locked.")
    }
    
    /// Sets up the timer for testing.
    /// - Parameters:
    ///   - unlocked: Whether the timer should consider itself unlocked or not.
    ///   - backgroundedDate: If not nil, the timer will consider the app to have been backgrounded at the specified date.
    private func setupTimer(unlocked: Bool, backgroundedAt backgroundedDate: Date? = nil) {
        timer = AppLockTimer(gracePeriod: 180)
        if unlocked {
            timer.registerUnlock()
        }
        if let backgroundedDate {
            timer.applicationDidEnterBackground(date: backgroundedDate)
        }
    }
}
