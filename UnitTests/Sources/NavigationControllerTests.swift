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
class NavigationControllerTests: XCTestCase {
    private var navigationController: NavigationController!
    
    override func setUp() {
        navigationController = NavigationController()
    }
    
    func testRoot() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)

        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
    }
    
    func testSingleSheet() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationController.presentSheet(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationController.sheetCoordinator)
        
        navigationController.dismissSheet()
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssertNil(navigationController.sheetCoordinator)
    }
    
    func testMultipleSheets() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationController.presentSheet(sheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssert(navigationController.coordinators.isEmpty)
        assertCoordinatorsEqual(sheetCoordinator, navigationController.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationController.presentSheet(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssert(navigationController.coordinators.isEmpty)
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationController.sheetCoordinator)
    }
    
    func testSinglePush() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationController.push(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationController.coordinators.first)
        
        navigationController.pop()
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssert(navigationController.coordinators.isEmpty)
    }
    
    func testMultiplePushes() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)
        
        var coordinators = [CoordinatorProtocol]()
        for _ in 0...10 {
            let coordinator = SomeTestCoordinator()
            coordinators.append(coordinator)
            navigationController.push(coordinator)
        }
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssertEqual(navigationController.coordinators.count, coordinators.count)
        
        for index in coordinators.indices {
            assertCoordinatorsEqual(coordinators[index], navigationController.coordinators[index])
        }
        
        navigationController.popToRoot()
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        XCTAssert(navigationController.coordinators.isEmpty)
    }
    
    func testRootReplacementDimissesTheRest() {
        let rootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(rootCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationController.presentSheet(sheetCoordinator)
        
        let pushedCoordinator = SomeTestCoordinator()
        navigationController.push(pushedCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationController.rootCoordinator)
        assertCoordinatorsEqual(pushedCoordinator, navigationController.coordinators.first)
        assertCoordinatorsEqual(sheetCoordinator, navigationController.sheetCoordinator)
        
        let newRootCoordinator = SomeTestCoordinator()
        navigationController.setRootCoordinator(newRootCoordinator)
        
        assertCoordinatorsEqual(newRootCoordinator, navigationController.rootCoordinator)
        XCTAssert(navigationController.coordinators.isEmpty)
        XCTAssertNil(navigationController.sheetCoordinator)
    }
    
    func testPushesDontReplaceSheet() {
        let sheetCoordinator = SomeTestCoordinator()
        navigationController.presentSheet(sheetCoordinator)
        
        let pushedCoordinator = SomeTestCoordinator()
        navigationController.push(pushedCoordinator)
        
        assertCoordinatorsEqual(pushedCoordinator, navigationController.coordinators.first)
        assertCoordinatorsEqual(sheetCoordinator, navigationController.sheetCoordinator)
        
        let newlyPushedCoordinator = SomeTestCoordinator()
        navigationController.push(newlyPushedCoordinator)
        
        assertCoordinatorsEqual(pushedCoordinator, navigationController.coordinators.first)
        assertCoordinatorsEqual(newlyPushedCoordinator, navigationController.coordinators.last)
        assertCoordinatorsEqual(sheetCoordinator, navigationController.sheetCoordinator)
    }
    
    func testPopDismissalCallbacks() {
        let pushedCoordinator = SomeTestCoordinator()
        
        let expectation = expectation(description: "Wait for callback")
        navigationController.push(pushedCoordinator) {
            expectation.fulfill()
        }
        
        navigationController.pop()
        waitForExpectations(timeout: 1.0)
    }
    
    func testPopToRootDismissalCallbacks() {
        navigationController.push(SomeTestCoordinator())
        navigationController.push(SomeTestCoordinator())
        
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationController.push(coordinator) {
            expectation.fulfill()
        }
        
        navigationController.popToRoot()
        waitForExpectations(timeout: 1.0)
    }
    
    func testSheetDismissalCallbac() {
        let coordinator = SomeTestCoordinator()
        let expectation = expectation(description: "Wait for callback")
        navigationController.presentSheet(coordinator) {
            expectation.fulfill()
        }
        
        navigationController.dismissSheet()
        waitForExpectations(timeout: 1.0)
    }
    
    func testRootReplacmeentCallbacks() {
        navigationController.setRootCoordinator(SomeTestCoordinator())
        
        let popExpectation = expectation(description: "Waiting for callback")
        navigationController.push(SomeTestCoordinator()) {
            popExpectation.fulfill()
        }
        
        let sheetExpectation = expectation(description: "Waiting for callback")
        navigationController.presentSheet(SomeTestCoordinator()) {
            sheetExpectation.fulfill()
        }
        
        navigationController.setRootCoordinator(SomeTestCoordinator())
        
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

private struct SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
