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
