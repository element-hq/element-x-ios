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

import Foundation

import XCTest

@testable import ElementX

@MainActor
class UserNotificationControllerTests: XCTestCase {
    private var notificationController: UserNotificationController!
    
    override func setUp() {
        notificationController = UserNotificationController(rootCoordinator: SplashScreenCoordinator())
    }
    
    func testNotificationQueueing() {
        notificationController.minimumDisplayDuration = 0.0
        
        notificationController.submitNotification(.init(id: "First", title: ""))
        notificationController.submitNotification(.init(id: "Second", title: ""))
        notificationController.submitNotification(.init(id: "Third", title: ""))
        
        XCTAssertEqual(notificationController.notificationQueue.count, 3)
        XCTAssertEqual(notificationController.notificationQueue[2].id, "Third")
        XCTAssertEqual(notificationController.notificationQueue[1].id, "Second")
        XCTAssertEqual(notificationController.notificationQueue[0].id, "First")
        
        notificationController.retractNotificationWithId("Second")
        
        XCTAssertEqual(notificationController.notificationQueue.count, 2)
        XCTAssertEqual(notificationController.notificationQueue[1].id, "Third")
        XCTAssertEqual(notificationController.notificationQueue[0].id, "First")
        
        notificationController.retractAllNotifications()
        
        XCTAssertEqual(notificationController.notificationQueue.count, 0)
    }
    
    func testChainedPresentation() {
        notificationController.minimumDisplayDuration = 0.25
        notificationController.nonPersistentDisplayDuration = 2.5
        
        notificationController.submitNotification(.init(id: "First", title: ""))
        notificationController.submitNotification(.init(id: "Second", title: ""))
        notificationController.submitNotification(.init(id: "Third", title: ""))
        
        XCTAssertEqual(notificationController.activeNotification?.id, "Third")
        
        let expectation = expectation(description: "Waiting for last notification to be dismissed")
        DispatchQueue.main.asyncAfter(deadline: .now() + notificationController.nonPersistentDisplayDuration) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(notificationController.notificationQueue.count, 2)
        XCTAssertEqual(notificationController.activeNotification?.id, "Second")
    }
    
    func testMinimumDisplayDuration() {
        notificationController.minimumDisplayDuration = 0.25
        notificationController.nonPersistentDisplayDuration = 2.5
        
        notificationController.submitNotification(.init(id: "First", title: ""))
        notificationController.submitNotification(.init(id: "Second", title: ""))
        notificationController.submitNotification(.init(id: "Third", title: ""))
        
        notificationController.retractNotificationWithId("Second")
        
        XCTAssertEqual(notificationController.notificationQueue.count, 3)
        
        let dismissalExpectation = expectation(description: "Waiting for minimum display duration to pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + notificationController.minimumDisplayDuration) {
            dismissalExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(notificationController.notificationQueue.count, 2)
        XCTAssertEqual(notificationController.activeNotification?.id, "Third")
        
        let dismissalExpectation2 = expectation(description: "Waiting for last notification to be dismissed")
        DispatchQueue.main.asyncAfter(deadline: .now() + notificationController.nonPersistentDisplayDuration) {
            dismissalExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(notificationController.notificationQueue.count, 1)
        XCTAssertEqual(notificationController.activeNotification?.id, "First")
    }
}
