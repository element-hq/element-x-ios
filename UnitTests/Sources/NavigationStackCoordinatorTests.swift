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

@Suite
@MainActor
struct NavigationStackCoordinatorTests {
    private var navigationStackCoordinator: NavigationStackCoordinator
    
    init() {
        navigationStackCoordinator = NavigationStackCoordinator()
    }
    
    @Test
    func root() {
        #expect(navigationStackCoordinator.rootCoordinator == nil)
        
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)

        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
    }
    
    @Test
    mutating func singleSheet() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationStackCoordinator.sheetCoordinator)
        
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.sheetCoordinator == nil)
    }
    
    @Test
    mutating func multipleSheets() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let sheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        assertCoordinatorsEqual(sheetCoordinator, navigationStackCoordinator.sheetCoordinator)
        
        let someOtherSheetCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setSheetCoordinator(someOtherSheetCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        assertCoordinatorsEqual(someOtherSheetCoordinator, navigationStackCoordinator.sheetCoordinator)
    }
    
    @Test
    mutating func singlePush() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        let coordinator = SomeTestCoordinator()
        navigationStackCoordinator.push(coordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        assertCoordinatorsEqual(coordinator, navigationStackCoordinator.stackCoordinators.first)
        
        navigationStackCoordinator.pop()
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    @Test
    mutating func multiplePushes() {
        let rootCoordinator = SomeTestCoordinator()
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        var coordinators = [CoordinatorProtocol]()
        for _ in 0...10 {
            let coordinator = SomeTestCoordinator()
            coordinators.append(coordinator)
            navigationStackCoordinator.push(coordinator)
        }
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == coordinators.count)
        
        for index in coordinators.indices {
            assertCoordinatorsEqual(coordinators[index], navigationStackCoordinator.stackCoordinators[index])
        }
        
        navigationStackCoordinator.popToRoot()
        
        assertCoordinatorsEqual(rootCoordinator, navigationStackCoordinator.rootCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    @Test
    mutating func rootReplacementDimissesTheRest() {
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
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    @Test
    mutating func pushesDontReplaceSheet() {
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
    
    // MARK: - Dismissal Callbacks
    
    @Test
    mutating func popDismissalCallbacks() async {
        let pushedCoordinator = SomeTestCoordinator()
        
        await confirmation("Wait for callback") { confirm in
            navigationStackCoordinator.push(pushedCoordinator) {
                confirm()
            }
            
            navigationStackCoordinator.pop()
        }
    }
    
    @Test
    mutating func popToRootDismissalCallbacks() async {
        navigationStackCoordinator.push(SomeTestCoordinator())
        navigationStackCoordinator.push(SomeTestCoordinator())
        
        let coordinator = SomeTestCoordinator()
        await confirmation("Wait for callback") { confirm in
            navigationStackCoordinator.push(coordinator) {
                confirm()
            }
            
            navigationStackCoordinator.popToRoot()
        }
    }
    
    @Test
    mutating func sheetDismissalCallback() async {
        let coordinator = SomeTestCoordinator()
        await confirmation("Wait for callback") { confirm in
            navigationStackCoordinator.setSheetCoordinator(coordinator) {
                confirm()
            }
            
            navigationStackCoordinator.setSheetCoordinator(nil)
        }
    }
    
    @Test
    mutating func rootReplacementCallbacks() async {
        navigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        await confirmation("Waiting for callback") { confirm in
            navigationStackCoordinator.push(SomeTestCoordinator()) {
                confirm()
            }
            
            navigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        }
    }
    
    // MARK: - Private
    
    private func assertCoordinatorsEqual(_ lhs: CoordinatorProtocol?, _ rhs: CoordinatorProtocol?) {
        guard let lhs = lhs as? SomeTestCoordinator,
              let rhs = rhs as? SomeTestCoordinator else {
            Issue.record("Coordinators are not the same")
            return
        }
        
        #expect(lhs.id == rhs.id)
    }
}

private class SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
