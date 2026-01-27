//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class NavigationTabCoordinatorTests: XCTestCase {
    enum TestTab { case tab, chats, spaces }
    private var navigationTabCoordinator: NavigationTabCoordinator<TestTab>!
    
    override func setUp() {
        navigationTabCoordinator = NavigationTabCoordinator()
    }
    
    func testTabs() {
        XCTAssertTrue(navigationTabCoordinator.tabCoordinators.isEmpty)
        
        let someCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: someCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [someCoordinator])
        
        let chatsCoordinator = SomeTestCoordinator()
        let spacesCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([
            .init(coordinator: chatsCoordinator, details: .init(tag: .chats, title: "Chats", icon: \.chat, selectedIcon: \.chatSolid)),
            .init(coordinator: spacesCoordinator, details: .init(tag: .spaces, title: "Spaces", icon: \.space, selectedIcon: \.spaceSolid))
        ])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [chatsCoordinator, spacesCoordinator])
    }
    
    func testSingleSheet() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let coordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(coordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(coordinator, navigationTabCoordinator.sheetCoordinator)
        
        navigationTabCoordinator.setSheetCoordinator(nil)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        XCTAssertNil(navigationTabCoordinator.sheetCoordinator)
    }
    
    func testMultipleSheets() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(sheetCoordinator, navigationTabCoordinator.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationTabCoordinator.sheetCoordinator)
    }
    
    func testFullScreenCover() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let coordinator = SomeTestCoordinator()
        navigationTabCoordinator.setFullScreenCoverCoordinator(coordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(coordinator, navigationTabCoordinator.fullScreenCoverCoordinator)
        
        navigationTabCoordinator.setFullScreenCoverCoordinator(nil)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        XCTAssertNil(navigationTabCoordinator.fullScreenCoverCoordinator)
    }
    
    func testOverlay() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let overlayCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setOverlayCoordinator(overlayCoordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(overlayCoordinator, navigationTabCoordinator.overlayCoordinator)
        
        // The coordinator should still be retained when changing the presentation mode.
        navigationTabCoordinator.setOverlayPresentationMode(.minimized)
        assertCoordinatorsEqual(overlayCoordinator, navigationTabCoordinator.overlayCoordinator)
        navigationTabCoordinator.setOverlayPresentationMode(.fullScreen)
        assertCoordinatorsEqual(overlayCoordinator, navigationTabCoordinator.overlayCoordinator)
        
        navigationTabCoordinator.setOverlayCoordinator(nil)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        XCTAssertNil(navigationTabCoordinator.overlayCoordinator)
    }
    
    // MARK: - Dismissal Callbacks
    
    func testTabDismissalCallbacks() {
        let chatsCoordinator = SomeTestCoordinator()
        let spacesCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        expectation.expectedFulfillmentCount = 2
        
        navigationTabCoordinator.setTabs([
            .init(coordinator: chatsCoordinator, details: .init(tag: .chats, title: "Chats", icon: \.chat, selectedIcon: \.chatSolid)) { expectation.fulfill() },
            .init(coordinator: spacesCoordinator, details: .init(tag: .spaces, title: "Spaces", icon: \.space, selectedIcon: \.spaceSolid)) { expectation.fulfill() }
        ])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [chatsCoordinator, spacesCoordinator])
        
        navigationTabCoordinator.setTabs([.init(coordinator: SomeTestCoordinator(), details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        waitForExpectations(timeout: 1.0)
    }
    
    func testSheetDismissalCallback() {
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationTabCoordinator.setSheetCoordinator(coordinator) {
            expectation.fulfill()
        }
        
        navigationTabCoordinator.setSheetCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testFullScreenCoverDismissalCallback() {
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationTabCoordinator.setFullScreenCoverCoordinator(coordinator) {
            expectation.fulfill()
        }
        
        navigationTabCoordinator.setFullScreenCoverCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testOverlayDismissalCallback() {
        let overlayCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationTabCoordinator.setOverlayCoordinator(overlayCoordinator) {
            expectation.fulfill()
        }
        
        navigationTabCoordinator.setOverlayCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testOverlayDismissalCallbackWhenChangingMode() {
        let overlayCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        expectation.isInverted = true
        navigationTabCoordinator.setOverlayCoordinator(overlayCoordinator) {
            expectation.fulfill()
        }
        
        navigationTabCoordinator.setOverlayPresentationMode(.minimized)
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
    
    private func assertCoordinatorsEqual(_ lhs: [CoordinatorProtocol], _ rhs: [CoordinatorProtocol]) {
        guard lhs.count == rhs.count else {
            XCTFail("Coordinators are not the same")
            return
        }
        
        for (index, coordinator) in lhs.enumerated() {
            assertCoordinatorsEqual(coordinator, rhs[index])
        }
    }
}

private class SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
