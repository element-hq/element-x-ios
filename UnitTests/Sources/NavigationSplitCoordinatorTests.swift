//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class NavigationSplitCoordinatorTests: XCTestCase {
    private var navigationSplitCoordinator: NavigationSplitCoordinator!
    
    override func setUp() {
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SomeTestCoordinator())
    }
    
    func testSidebar() {
        XCTAssertNil(navigationSplitCoordinator.sidebarCoordinator)
        XCTAssertNil(navigationSplitCoordinator.detailCoordinator)
        
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
    }
    
    func testDetail() {
        XCTAssertNil(navigationSplitCoordinator.sidebarCoordinator)
        XCTAssertNil(navigationSplitCoordinator.detailCoordinator)
        
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
    }
    
    func testSidebarAndDetail() {
        XCTAssertNil(navigationSplitCoordinator.sidebarCoordinator)
        XCTAssertNil(navigationSplitCoordinator.detailCoordinator)
        
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
    }
    
    func testSingleSheet() {
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        assertCoordinatorsEqual(sheetCoordinator, navigationSplitCoordinator.sheetCoordinator)
        
        navigationSplitCoordinator.setSheetCoordinator(nil)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        XCTAssertNil(navigationSplitCoordinator.sheetCoordinator)
    }
    
    func testMultipleSheets() {
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        assertCoordinatorsEqual(sheetCoordinator, navigationSplitCoordinator.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSheetCoordinator(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationSplitCoordinator.sheetCoordinator)
    }
    
    func testFullScreenCover() {
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let fullScreenCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setFullScreenCoverCoordinator(fullScreenCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        assertCoordinatorsEqual(fullScreenCoordinator, navigationSplitCoordinator.fullScreenCoverCoordinator)
        
        navigationSplitCoordinator.setFullScreenCoverCoordinator(nil)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        XCTAssertNil(navigationSplitCoordinator.fullScreenCoverCoordinator)
    }
    
    func testOverlay() {
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let overlayCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setOverlayCoordinator(overlayCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        assertCoordinatorsEqual(overlayCoordinator, navigationSplitCoordinator.overlayCoordinator)
        
        // The coordinator should still be retained when changing the presentation mode.
        navigationSplitCoordinator.setOverlayPresentationMode(.minimized)
        assertCoordinatorsEqual(overlayCoordinator, navigationSplitCoordinator.overlayCoordinator)
        navigationSplitCoordinator.setOverlayPresentationMode(.fullScreen)
        assertCoordinatorsEqual(overlayCoordinator, navigationSplitCoordinator.overlayCoordinator)
        
        navigationSplitCoordinator.setOverlayCoordinator(nil)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
        XCTAssertNil(navigationSplitCoordinator.overlayCoordinator)
    }
    
    func testSidebarReplacementCallbacks() {
        let sidebarCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setSidebarCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testDetailReplacementCallbacks() {
        let detailCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setDetailCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testSheetDismissalCallback() {
        let sheetCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationSplitCoordinator.setSheetCoordinator(sheetCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setSheetCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testFullScreenCoverDismissalCallback() {
        let fullScreenCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationSplitCoordinator.setFullScreenCoverCoordinator(fullScreenCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setFullScreenCoverCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testOverlayDismissalCallback() {
        let overlayCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationSplitCoordinator.setOverlayCoordinator(overlayCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setOverlayCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testOverlayDismissalCallbackWhenChangingMode() {
        let overlayCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        expectation.isInverted = true
        navigationSplitCoordinator.setOverlayCoordinator(overlayCoordinator) {
            expectation.fulfill()
        }
        
        navigationSplitCoordinator.setOverlayPresentationMode(.minimized)
        waitForExpectations(timeout: 1.0)
    }
    
    func testEmbeddedStackPresentsSheetThroughSplit() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let sheetCoordinator = SomeTestCoordinator()
        sidebarNavigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sheetCoordinator, sidebarNavigationStackCoordinator.sheetCoordinator)
        assertCoordinatorsEqual(sheetCoordinator, navigationSplitCoordinator.sheetCoordinator)
    }
    
    func testSplitTracksEmbeddedStackRootChanges() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let expectation = expectation(description: "Coordinators should match")
        DispatchQueue.main.async {
            self.assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, self.navigationSplitCoordinator.compactLayoutRootCoordinator)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testSplitTracksEmbeddedStackChanges() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        
        sidebarNavigationStackCoordinator.push(SomeTestCoordinator())
        
        let expectation = expectation(description: "Coordinators should match")
        DispatchQueue.main.async {
            XCTAssertEqual(sidebarNavigationStackCoordinator.stackCoordinators.count, self.navigationSplitCoordinator.compactLayoutStackCoordinators.count)
            for index in sidebarNavigationStackCoordinator.stackCoordinators.indices {
                self.assertCoordinatorsEqual(sidebarNavigationStackCoordinator.stackCoordinators[index], self.navigationSplitCoordinator.compactLayoutStackCoordinators[index])
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testSplitPropagatesCompactStackChanges() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        sidebarNavigationStackCoordinator.push(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        XCTAssertEqual(sidebarNavigationStackCoordinator.stackCoordinators.count, navigationSplitCoordinator.compactLayoutStackCoordinators.count)
        
        navigationSplitCoordinator.compactLayoutStackModules.removeAll()
        
        XCTAssertTrue(sidebarNavigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    func testCompactStackCreation() {
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())
        sidebarCoordinator.push(SomeTestCoordinator())
        
        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let expectation = expectation(description: "Coordinators should match")
        DispatchQueue.main.async {
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, sidebarCoordinator.stackCoordinators.first)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[1].coordinator, detailCoordinator.rootCoordinator)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[2].coordinator, detailCoordinator.stackCoordinators.first)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[3].coordinator, detailCoordinator.stackCoordinators.last)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testRemovesDetailRootFromCompactStack() {
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        let expectation = expectation(description: "Coordinators should match")
        DispatchQueue.main.async {
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, detailCoordinator.rootCoordinator)
            self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[1].coordinator, detailCoordinator.stackCoordinators.first)
            
            detailCoordinator.setRootCoordinator(nil)
            
            DispatchQueue.main.async {
                self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, detailCoordinator.stackCoordinators.first)
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testSetRootDetailToNilAfterPoppingToRoot() {
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SomeTestCoordinator())
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())

        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())

        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)

        let expectation = expectation(description: "Details coordinator should be nil, and the compact layout revert to the sidebar root")
        DispatchQueue.main.async {
            detailCoordinator.popToRoot(animated: true)
            self.navigationSplitCoordinator.setDetailCoordinator(nil)
            DispatchQueue.main.async {
                XCTAssertNil(self.navigationSplitCoordinator.detailCoordinator)
                self.assertCoordinatorsEqual(self.navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                XCTAssertTrue(self.navigationSplitCoordinator.compactLayoutStackModules.isEmpty)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Private
    
    private func assertCoordinatorsEqual(_ lhs: CoordinatorProtocol?, _ rhs: CoordinatorProtocol?) {
        if lhs == nil, rhs == nil {
            return
        }
        
        guard let lhs = lhs as? SomeTestCoordinator,
              let rhs = rhs as? SomeTestCoordinator else {
            XCTFail("Coordinators are not the same: \(String(describing: lhs)) != \(String(describing: rhs))")
            return
        }
        
        XCTAssertEqual(lhs.id, rhs.id)
    }
}

private class SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
