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

    func testSetRootDetailToNil() {
        // Create the split with some test coordinator
        // Add a STACK  of coordinators to the details only
        // Remove entirely the root detail coordinator
        // TODO: Write a test
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
