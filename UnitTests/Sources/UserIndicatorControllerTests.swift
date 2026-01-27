//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import XCTest

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
    
    func testChainedPresentation() async throws {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        XCTAssertEqual(indicatorController.activeIndicator?.id, "Third")
        
        let fulfillment = deferFulfillment(indicatorController.$activeIndicator, message: "Waiting for last indicator to be dismissed") { indicator in
            indicator?.id == "Second"
        }
        
        try await fulfillment.fulfill()
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 2)
        XCTAssertEqual(indicatorController.activeIndicator?.id, "Second")
    }
    
    func testMinimumDisplayDuration() async throws {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 3)
        
        var fulfillment = deferFulfillment(indicatorController.$activeIndicator, message: "Waiting for minimum display duration to pass") { indicator in
            indicator?.id == "First"
        }
        
        indicatorController.retractIndicatorWithId("Second")
        
        try await fulfillment.fulfill()
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 1)
        XCTAssertEqual(indicatorController.activeIndicator?.id, "First")
        
        fulfillment = deferFulfillment(indicatorController.$activeIndicator, message: "Waiting for last indicator to be dismissed") { indicator in
            indicator == nil
        }
        
        try await fulfillment.fulfill()
        
        XCTAssertEqual(indicatorController.indicatorQueue.count, 0)
        XCTAssertNil(indicatorController.activeIndicator)
    }
}
