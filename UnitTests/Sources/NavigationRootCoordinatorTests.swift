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

@MainActor
struct NavigationRootCoordinatorTests {
    private var navigationRootCoordinator: NavigationRootCoordinator
    
    init() {
        navigationRootCoordinator = NavigationRootCoordinator()
    }
    
    @Test
    func rootChanges() {
        #expect(navigationRootCoordinator.rootCoordinator == nil)
        
        let firstRootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(firstRootCoordinator)
        
        assertCoordinatorsEqual(firstRootCoordinator, navigationRootCoordinator.rootCoordinator)
        
        let secondRootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(secondRootCoordinator)
        
        assertCoordinatorsEqual(secondRootCoordinator, navigationRootCoordinator.rootCoordinator)
    }
    
    @Test
    func overlay() {
        let rootCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setRootCoordinator(rootCoordinator)
        
        let overlayCoordinator = SomeTestCoordinator()
        navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator)
        
        assertCoordinatorsEqual(rootCoordinator, navigationRootCoordinator.rootCoordinator)
        assertCoordinatorsEqual(overlayCoordinator, navigationRootCoordinator.overlayCoordinator)
        
        // The coordinator should still be retained when changing the presentation mode.
        navigationRootCoordinator.setOverlayPresentationMode(.minimized)
        assertCoordinatorsEqual(overlayCoordinator, navigationRootCoordinator.overlayCoordinator)
        navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
        assertCoordinatorsEqual(overlayCoordinator, navigationRootCoordinator.overlayCoordinator)
        
        navigationRootCoordinator.setOverlayCoordinator(nil)
        
        assertCoordinatorsEqual(rootCoordinator, navigationRootCoordinator.rootCoordinator)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    @Test
    func overlaySurvivesRootChanges() async {
        let overlayCoordinator = SomeTestCoordinator()
        await waitForConfirmation("Changing the root must not tear the overlay down", expectedCount: 0, timeout: .seconds(1)) { confirmation in
            navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator) { confirmation() }
            navigationRootCoordinator.setRootCoordinator(SomeTestCoordinator())
            navigationRootCoordinator.setRootCoordinator(nil)
        }
        assertCoordinatorsEqual(overlayCoordinator, navigationRootCoordinator.overlayCoordinator)
    }
    
    // MARK: - Dismissal Callbacks
    
    @Test
    func replacementDismissalCallbacks() async {
        #expect(navigationRootCoordinator.rootCoordinator == nil)
        
        let rootCoordinator = SomeTestCoordinator()
        
        await confirmation("Wait for callback") { confirm in
            navigationRootCoordinator.setRootCoordinator(rootCoordinator) {
                confirm()
            }
            
            navigationRootCoordinator.setRootCoordinator(nil)
        }
    }
    
    @Test
    func overlayDismissalCallback() async {
        let overlayCoordinator = SomeTestCoordinator()
        
        await confirmation("Wait for callback") { confirm in
            navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator) {
                confirm()
            }
            
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    @Test
    func overlayDismissalCallbackWhenChangingMode() async {
        let overlayCoordinator = SomeTestCoordinator()
        
        await waitForConfirmation("Callback should not be called when just changing mode",
                                  expectedCount: 0,
                                  timeout: .seconds(1)) { confirmation in
            navigationRootCoordinator.setOverlayCoordinator(overlayCoordinator) {
                confirmation()
            }
            
            navigationRootCoordinator.setOverlayPresentationMode(.minimized)
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
