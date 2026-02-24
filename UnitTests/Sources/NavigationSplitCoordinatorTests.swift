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
struct NavigationSplitCoordinatorTests {
    private var navigationSplitCoordinator: NavigationSplitCoordinator
    
    init() {
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SomeTestCoordinator())
    }
    
    @Test
    func sidebar() {
        #expect(navigationSplitCoordinator.sidebarCoordinator == nil)
        #expect(navigationSplitCoordinator.detailCoordinator == nil)
        
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
    }
    
    @Test
    func detail() {
        #expect(navigationSplitCoordinator.sidebarCoordinator == nil)
        #expect(navigationSplitCoordinator.detailCoordinator == nil)
        
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
    }
    
    @Test
    func sidebarAndDetail() {
        #expect(navigationSplitCoordinator.sidebarCoordinator == nil)
        #expect(navigationSplitCoordinator.detailCoordinator == nil)
        
        let sidebarCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        
        let detailCoordinator = SomeTestCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        assertCoordinatorsEqual(sidebarCoordinator, navigationSplitCoordinator.sidebarCoordinator)
        assertCoordinatorsEqual(detailCoordinator, navigationSplitCoordinator.detailCoordinator)
    }
    
    @Test
    func singleSheet() {
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
        #expect(navigationSplitCoordinator.sheetCoordinator == nil)
    }
    
    @Test
    func multipleSheets() {
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
    
    @Test
    func fullScreenCover() {
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
        #expect(navigationSplitCoordinator.fullScreenCoverCoordinator == nil)
    }
    
    // MARK: - Dismissal Callbacks
    
    @Test
    func sidebarReplacementCallbacks() async {
        let sidebarCoordinator = SomeTestCoordinator()
        
        await waitForConfirmation("Wait for callback", timeout: .seconds(1)) { confirm in
            navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator) {
                confirm()
            }
            
            navigationSplitCoordinator.setSidebarCoordinator(nil)
        }
    }
    
    @Test
    func detailReplacementCallbacks() async {
        let detailCoordinator = SomeTestCoordinator()
        
        await waitForConfirmation("Wait for callback", timeout: .seconds(1)) { confirm in
            navigationSplitCoordinator.setDetailCoordinator(detailCoordinator) {
                confirm()
            }
            
            navigationSplitCoordinator.setDetailCoordinator(nil)
        }
    }
    
    @Test
    func sheetDismissalCallback() async {
        let sheetCoordinator = SomeTestCoordinator()
        
        await waitForConfirmation("Wait for callback", timeout: .seconds(1)) { confirm in
            navigationSplitCoordinator.setSheetCoordinator(sheetCoordinator) {
                confirm()
            }
            
            navigationSplitCoordinator.setSheetCoordinator(nil)
        }
    }
    
    @Test
    func fullScreenCoverDismissalCallback() async {
        let fullScreenCoordinator = SomeTestCoordinator()
        
        await waitForConfirmation("Wait for callback", timeout: .seconds(1)) { confirm in
            navigationSplitCoordinator.setFullScreenCoverCoordinator(fullScreenCoordinator) {
                confirm()
            }
            
            navigationSplitCoordinator.setFullScreenCoverCoordinator(nil)
        }
    }
    
    // MARK: - Advanced
    
    @Test
    func embeddedStackPresentsSheetThroughSplit() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let sheetCoordinator = SomeTestCoordinator()
        sidebarNavigationStackCoordinator.setSheetCoordinator(sheetCoordinator)
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sheetCoordinator, sidebarNavigationStackCoordinator.sheetCoordinator)
        assertCoordinatorsEqual(sheetCoordinator, navigationSplitCoordinator.sheetCoordinator)
    }
    
    @Test
    func splitTracksEmbeddedStackRootChanges() async {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        await waitForConfirmation("Coordinators should match", timeout: .seconds(1)) { confirm in
            DispatchQueue.main.async {
                assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
                confirm()
            }
        }
    }
    
    @Test
    func splitTracksEmbeddedStackChanges() async {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        
        sidebarNavigationStackCoordinator.push(SomeTestCoordinator())
        
        await waitForConfirmation("Coordinators should match", timeout: .seconds(1)) { confirm in
            DispatchQueue.main.async {
                #expect(sidebarNavigationStackCoordinator.stackCoordinators.count == navigationSplitCoordinator.compactLayoutStackCoordinators.count)
                for index in sidebarNavigationStackCoordinator.stackCoordinators.indices {
                    assertCoordinatorsEqual(sidebarNavigationStackCoordinator.stackCoordinators[index], navigationSplitCoordinator.compactLayoutStackCoordinators[index])
                }
                confirm()
            }
        }
    }
    
    @Test
    func splitPropagatesCompactStackChanges() {
        let sidebarNavigationStackCoordinator = NavigationStackCoordinator(navigationSplitCoordinator: navigationSplitCoordinator)
        sidebarNavigationStackCoordinator.setRootCoordinator(SomeTestCoordinator())
        sidebarNavigationStackCoordinator.push(SomeTestCoordinator())
                
        navigationSplitCoordinator.setSidebarCoordinator(sidebarNavigationStackCoordinator)
        
        assertCoordinatorsEqual(sidebarNavigationStackCoordinator.rootCoordinator, navigationSplitCoordinator.compactLayoutRootCoordinator)
        #expect(sidebarNavigationStackCoordinator.stackCoordinators.count == navigationSplitCoordinator.compactLayoutStackCoordinators.count)
        
        navigationSplitCoordinator.compactLayoutStackModules.removeAll()
        
        #expect(sidebarNavigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    @Test
    func compactStackCreation() async {
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())
        sidebarCoordinator.push(SomeTestCoordinator())
        
        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        await waitForConfirmation("Coordinators should match", timeout: .seconds(1)) { confirm in
            DispatchQueue.main.async {
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, sidebarCoordinator.stackCoordinators.first)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[1].coordinator, detailCoordinator.rootCoordinator)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[2].coordinator, detailCoordinator.stackCoordinators.first)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[3].coordinator, detailCoordinator.stackCoordinators.last)
                confirm()
            }
        }
    }
    
    @Test
    func removesDetailRootFromCompactStack() async {
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())
        
        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())
        
        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)
        
        await waitForConfirmation("Coordinators should match", timeout: .seconds(1)) { confirm in
            DispatchQueue.main.async {
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, detailCoordinator.rootCoordinator)
                assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[1].coordinator, detailCoordinator.stackCoordinators.first)
                
                detailCoordinator.setRootCoordinator(nil)
                
                DispatchQueue.main.async {
                    assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                    assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutStackModules[0].coordinator, detailCoordinator.stackCoordinators.first)
                }
                
                confirm()
            }
        }
    }

    @Test
    mutating func setRootDetailToNilAfterPoppingToRoot() async {
        navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SomeTestCoordinator())
        let sidebarCoordinator = NavigationStackCoordinator()
        sidebarCoordinator.setRootCoordinator(SomeTestCoordinator())

        let detailCoordinator = NavigationStackCoordinator()
        detailCoordinator.setRootCoordinator(SomeTestCoordinator())
        detailCoordinator.push(SomeTestCoordinator())

        navigationSplitCoordinator.setSidebarCoordinator(sidebarCoordinator)
        navigationSplitCoordinator.setDetailCoordinator(detailCoordinator)

        await waitForConfirmation("Details coordinator should be nil, and the compact layout revert to the sidebar root",
                                  timeout: .seconds(1)) { [navigationSplitCoordinator] confirm in
            DispatchQueue.main.async {
                detailCoordinator.popToRoot(animated: true)
                navigationSplitCoordinator.setDetailCoordinator(nil)
                DispatchQueue.main.async {
                    #expect(navigationSplitCoordinator.detailCoordinator == nil)
                    assertCoordinatorsEqual(navigationSplitCoordinator.compactLayoutRootCoordinator, sidebarCoordinator.rootCoordinator)
                    #expect(navigationSplitCoordinator.compactLayoutStackModules.isEmpty)
                    confirm()
                }
            }
        }
    }
}

// MARK: - Private

private func assertCoordinatorsEqual(_ lhs: CoordinatorProtocol?, _ rhs: CoordinatorProtocol?) {
    if lhs == nil, rhs == nil {
        return
    }
    
    guard let lhs = lhs as? SomeTestCoordinator,
          let rhs = rhs as? SomeTestCoordinator else {
        Issue.record("Coordinators are not the same: \(String(describing: lhs)) != \(String(describing: rhs))")
        return
    }
    
    #expect(lhs.id == rhs.id)
}

private class SomeTestCoordinator: CoordinatorProtocol {
    let id = UUID()
}
