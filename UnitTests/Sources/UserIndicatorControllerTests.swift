//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

import XCTest

@testable import ElementX

@MainActor
class UserIndicatorControllerTests: XCTestCase {
    private var indicatorController: UserIndicatorController!
    
    override func setUp() {
        indicatorController = UserIndicatorController()
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
