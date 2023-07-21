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
class UserIndicatorControllerTests: XCTestCase {
    private var indicatorController: UserIndicatorController!
    
    override func setUp() {
        indicatorController = UserIndicatorController(rootCoordinator: PlaceholderScreenCoordinator())
    }
    
    func testIndicatorQueueing() {
        indicatorController.minimumDisplayDuration = 0.0
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 3)
        XCTAssertEqual(indicatorController.indicatorQueue[2].id, "Third")
        XCTAssertEqual(indicatorController.indicatorQueue[1].id, "Second")
        XCTAssertEqual(indicatorController.indicatorQueue[0].id, "First")
        
        indicatorController.retractIndicatorWithId("Second")
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 2)
        XCTAssertEqual(indicatorController.indicatorQueue[1].id, "Third")
        XCTAssertEqual(indicatorController.indicatorQueue[0].id, "First")
        
        indicatorController.retractAllIndicators()
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 0)
    }
    
    func testChainedPresentation() {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        XCTAssertEqual(indicatorController.activeIndicator?.id, "Third")
        
        let expectation = expectation(description: "Waiting for last indicator to be dismissed")
        DispatchQueue.main.asyncAfter(deadline: .now() + indicatorController.nonPersistentDisplayDuration) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 2)
        XCTAssertEqual(indicatorController.activeIndicator?.id, "Second")
    }
    
    func testMinimumDisplayDuration() {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        indicatorController.retractIndicatorWithId("Second")
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 3)
        
        let dismissalExpectation = expectation(description: "Waiting for minimum display duration to pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + indicatorController.minimumDisplayDuration) {
            dismissalExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 2)
        XCTAssertEqual(indicatorController.activeIndicator?.id, "Third")
        
        let dismissalExpectation2 = expectation(description: "Waiting for last indicator to be dismissed")
        DispatchQueue.main.asyncAfter(deadline: .now() + indicatorController.nonPersistentDisplayDuration) {
            dismissalExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 1)
        XCTAssertEqual(indicatorController.activeIndicator?.id, "First")
    }
}
