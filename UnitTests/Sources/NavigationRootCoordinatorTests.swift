//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class NavigationRootCoordinatorTests: XCTestCase {
    private var navigationRootCoordinator: NavigationRootCoordinator!
    
    override func setUp() {
        navigationRootCoordinator = NavigationRootCoordinator()
    }
    
    func testRootChanges() {
        XCTAssertNil(navigationRootCoordinator.rootCoordinator)
        
        let firstRootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(firstRootCoordinator)

        assertCoordinatorsEqual(firstRootCoordinator, navigationRootCoordinator.rootCoordinator)
        
        let secondRootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(secondRootCoordinator)
        
        assertCoordinatorsEqual(secondRootCoordinator, navigationRootCoordinator.rootCoordinator)
    }
    
    func testOverlay() {
        let rootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(rootCoordinator)
        
        let overlayCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationRootCoordinator.rootCoordinator)
        assertCoordinatorsEqual(overlayCoordinator, navigationRootCoordinator.overlayCoordinator)
        
        navigationRootCoordinator.setOverlayCoordinator(nil)
        
        assertCoordinatorsEqual(rootCoordinator, navigationRootCoordinator.rootCoordinator)
        XCTAssertNil(navigationRootCoordinator.overlayCoordinator)
    }
    
    func testReplacementDismissalCallbacks() {
        XCTAssertNil(navigationRootCoordinator.rootCoordinator)
        
        let rootCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationRootCoordinator.setRootCoordinator(rootCoordinator) {
            expectation.fulfill()
        }
        
        navigationRootCoordinator.setRootCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testOverlayDismissalCallback() {
        let overlayCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator) {
            expectation.fulfill()
        }
        
        navigationRootCoordinator.setOverlayCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Private
    
    private func assertCoordinatorsEqual(_ lhs: CoordinatorProtocol?, _ rhs: CoordinatorProtocol?) {
        guard let lhs = lhs as? SomeTestCoordinator,
              let rhs = rhs as? SomeTestCoordinator else {
            XCTFail("Coordinators are not the same")
            return
        }
        
        XCTAssertEqual(lhs.id, rhs.id)
    }
}

private class SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
