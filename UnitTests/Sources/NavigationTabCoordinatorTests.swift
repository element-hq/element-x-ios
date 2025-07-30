//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class NavigationTabCoordinatorTests: XCTestCase {
    private var navigationTabCoordinator: NavigationTabCoordinator!
    
    override func setUp() {
        navigationTabCoordinator = NavigationTabCoordinator()
    }
    
    func testTabs() {
        XCTAssertTrue(navigationTabCoordinator.tabCoordinators.isEmpty)
        
        let someCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: someCoordinator, title: "Whatever", icon: \.help, selectedIcon: \.helpSolid)])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [someCoordinator])
        
        let chatsCoordinator = SomeTestCoordinator()
        let spacesCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([
            .init(coordinator: chatsCoordinator, title: "Chats", icon: \.chat, selectedIcon: \.chatSolid),
            .init(coordinator: spacesCoordinator, title: "Spaces", icon: \.space, selectedIcon: \.spaceSolid)
        ])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [chatsCoordinator, spacesCoordinator])
    }
    
    func testSingleSheet() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, title: "Tab", icon: \.help, selectedIcon: \.helpSolid)])
        
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
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, title: "Tab", icon: \.help, selectedIcon: \.helpSolid)])
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(sheetCoordinator, navigationTabCoordinator.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationTabCoordinator.sheetCoordinator)
    }
    
    func testTabDismissalCallbacks() {
        let chatsCoordinator = SomeTestCoordinator()
        let spacesCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        expectation.expectedFulfillmentCount = 2
        
        navigationTabCoordinator.setTabs([
            .init(coordinator: chatsCoordinator, title: "Chats", icon: \.chat, selectedIcon: \.chatSolid) { expectation.fulfill() },
            .init(coordinator: spacesCoordinator, title: "Spaces", icon: \.space, selectedIcon: \.spaceSolid) { expectation.fulfill() }
        ])
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [chatsCoordinator, spacesCoordinator])
        
        navigationTabCoordinator.setTabs([.init(coordinator: SomeTestCoordinator(), title: "Whatever", icon: \.help, selectedIcon: \.helpSolid)])
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
