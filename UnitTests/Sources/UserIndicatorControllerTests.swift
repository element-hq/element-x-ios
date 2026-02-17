//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
@Suite
struct UserIndicatorControllerTests {
    private var indicatorController: UserIndicatorController
    
    init() {
        indicatorController = UserIndicatorController()
    }
    
    @Test
    mutating func indicatorQueueing() {
        indicatorController.minimumDisplayDuration = 0.0
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        #expect(indicatorController.indicatorQueue.count == 3)
        #expect(indicatorController.indicatorQueue[2].id == "Third")
        #expect(indicatorController.indicatorQueue[1].id == "Second")
        #expect(indicatorController.indicatorQueue[0].id == "First")
        
        indicatorController.retractIndicatorWithId("Second")
        
        #expect(indicatorController.indicatorQueue.count == 2)
        #expect(indicatorController.indicatorQueue[1].id == "Third")
        #expect(indicatorController.indicatorQueue[0].id == "First")
        
        indicatorController.retractAllIndicators()
        
        #expect(indicatorController.indicatorQueue.count == 0)
    }
    
    @Test
    mutating func chainedPresentation() async throws {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        #expect(indicatorController.activeIndicator?.id == "Third")
        
        let fulfillment = deferFulfillment(indicatorController.$activeIndicator) { indicator in
            indicator?.id == "Second"
        }
        
        try await fulfillment.fulfill()
        
        #expect(indicatorController.indicatorQueue.count == 2)
        #expect(indicatorController.activeIndicator?.id == "Second")
    }
    
    @Test
    mutating func minimumDisplayDuration() async throws {
        indicatorController.minimumDisplayDuration = 0.25
        indicatorController.nonPersistentDisplayDuration = 2.5
        
        indicatorController.submitIndicator(.init(id: "First", title: ""))
        indicatorController.submitIndicator(.init(id: "Second", title: ""))
        indicatorController.submitIndicator(.init(id: "Third", title: ""))
        
        #expect(indicatorController.indicatorQueue.count == 3)
        
        var fulfillment = deferFulfillment(indicatorController.$activeIndicator) { indicator in
            indicator?.id == "First"
        }
        
        indicatorController.retractIndicatorWithId("Second")
        
        try await fulfillment.fulfill()
        
        #expect(indicatorController.indicatorQueue.count == 1)
        #expect(indicatorController.activeIndicator?.id == "First")
        
        fulfillment = deferFulfillment(indicatorController.$activeIndicator) { indicator in
            indicator == nil
        }
        
        try await fulfillment.fulfill()
        
        #expect(indicatorController.indicatorQueue.count == 0)
        #expect(indicatorController.activeIndicator == nil)
    }
}
