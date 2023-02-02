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
class NavigationStackCoordinatorTests: XCTestCase {
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    override func setUp() {
        navigationStackCoordinator = NavigationStackCoordinator()
    }
    
    func testRoot() {
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
        
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)

        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
    }
    
    func testSingleSheet() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationStackCoordinator.sheetCoordinator)
        
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssertNil(navigationStackCoordinator.sheetCoordinator)
    }
    
    func testMultipleSheets() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.isEmpty)
        assertCoordinatorsEqual(sheetCoordinator, navigationStackCoordinator.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.isEmpty)
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationStackCoordinator.sheetCoordinator)
    }
    
    func testSinglePush() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationStackCoordinator.push(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationStackCoordinator.stackCoordinators.first)
        
        navigationStackCoordinator.pop()
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    func testMultiplePushes() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        var coordinators = [CoordinatorProtocol]()
        for _ in 0...10 {
            let coordinator = SomeTestCoordinator()
            coordinators.append(coordinator)
            navigationStackCoordinator.push(coordinator)
        }
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, coordinators.count)
        
        for index in coordinators.indices {
            assertCoordinatorsEqual(coordinators[index], navigationStackCoordinator.stackCoordinators[index])
        }
        
        navigationStackCoordinator.popToRoot()
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    func testRootReplacementDimissesTheRest() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        let pushedCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.push(pushedCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        assertCoordinatorsEqual(pushedCoordinator, navigationStackCoordinator.stackCoordinators.first)
        assertCoordinatorsEqual(sheetCoordinator, navigationStackCoordinator.sheetCoordinator)
        
        let newRootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(newRootCoordinator)
        
        assertCoordinatorsEqual(newRootCoordinator, navigationStackCoordinator.rootCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    func testPushesDontReplaceSheet() {
        let sheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        let pushedCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.push(pushedCoordinator)
        
        assertCoordinatorsEqual(pushedCoordinator, navigationStackCoordinator.stackCoordinators.first)
        assertCoordinatorsEqual(sheetCoordinator, navigationStackCoordinator.sheetCoordinator)
        
        let newlyPushedCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.push(newlyPushedCoordinator)
        
        assertCoordinatorsEqual(pushedCoordinator, navigationStackCoordinator.stackCoordinators.first)
        assertCoordinatorsEqual(newlyPushedCoordinator, navigationStackCoordinator.stackCoordinators.last)
        assertCoordinatorsEqual(sheetCoordinator, navigationStackCoordinator.sheetCoordinator)
    }
    
    func testPopDismissalCallbacks() {
        let pushedCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationStackCoordinator.push(pushedCoordinator) {
            expectation.fulfill()
        }
        
        navigationStackCoordinator.pop()
        waitForExpectations(timeout: 1.0)
    }
    
    func testPopToRootDismissalCallbacks() {
        navigationStackCoordinator.push(SomeTestCoordinator())
        navigationStackCoordinator.push(SomeTestCoordinator())
        
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationStackCoordinator.push(coordinator) {
            expectation.fulfill()
        }
        
        navigationStackCoordinator.popToRoot()
        waitForExpectations(timeout: 1.0)
    }
    
    func testSheetDismissalCallback() {
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationStackCoordinator.setSheetCoordinator(coordinator) {
            expectation.fulfill()
        }
        
        navigationStackCoordinator.setSheetCoordinator(nil)
        waitForExpectations(timeout: 1.0)
    }
    
    func testRootReplacementCallbacks() {
        navigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let popExpectation = expectation(description: "Waiting for callback")
        navigationStackCoordinator.push(SomeTestCoordinator()) {
            popExpectation.fulfill()
        }
        
        navigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
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
