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
struct NavigationTabCoordinatorTests {
    enum TestTab { case tab, chats, spaces }
    private var navigationTabCoordinator: NavigationTabCoordinator<TestTab>
    
    init() {
        navigationTabCoordinator = NavigationTabCoordinator()
    }
    
    @Test
    mutating func tabs() {
        #expect(navigationTabCoordinator.tabCoordinators.isEmpty)
        
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
    
    @Test
    mutating func singleSheet() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let coordinator = SomeTestCoordinator()
        navigationTabCoordinator.setSheetCoordinator(coordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(coordinator, navigationTabCoordinator.sheetCoordinator)
        
        navigationTabCoordinator.setSheetCoordinator(nil)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        #expect(navigationTabCoordinator.sheetCoordinator == nil)
    }
    
    @Test
    mutating func multipleSheets() {
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
    
    @Test
    mutating func fullScreenCover() {
        let tabCoordinator = SomeTestCoordinator()
        navigationTabCoordinator.setTabs([.init(coordinator: tabCoordinator, details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        
        let coordinator = SomeTestCoordinator()
        navigationTabCoordinator.setFullScreenCoverCoordinator(coordinator)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        assertCoordinatorsEqual(coordinator, navigationTabCoordinator.fullScreenCoverCoordinator)
        
        navigationTabCoordinator.setFullScreenCoverCoordinator(nil)
        
        assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [tabCoordinator])
        #expect(navigationTabCoordinator.fullScreenCoverCoordinator == nil)
    }
    
    @Test
    mutating func overlay() {
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
        #expect(navigationTabCoordinator.overlayCoordinator == nil)
    }
    
    // MARK: - Dismissal Callbacks
    
    @Test
    mutating func tabDismissalCallbacks() async {
        let chatsCoordinator = SomeTestCoordinator()
        let spacesCoordinator = SomeTestCoordinator()
        
        await confirmation("Wait for callback", expectedCount: 2) { confirm in
            navigationTabCoordinator.setTabs([
                .init(coordinator: chatsCoordinator, details: .init(tag: .chats, title: "Chats", icon: \.chat, selectedIcon: \.chatSolid)) { confirm() },
                .init(coordinator: spacesCoordinator, details: .init(tag: .spaces, title: "Spaces", icon: \.space, selectedIcon: \.spaceSolid)) { confirm() }
            ])
            assertCoordinatorsEqual(navigationTabCoordinator.tabCoordinators, [chatsCoordinator, spacesCoordinator])
            
            navigationTabCoordinator.setTabs([.init(coordinator: SomeTestCoordinator(), details: .init(tag: .tab, title: "Tab", icon: \.help, selectedIcon: \.helpSolid))])
        }
    }
    
    @Test
    mutating func sheetDismissalCallback() async {
        let coordinator = SomeTestCoordinator()
        await confirmation("Wait for callback") { confirm in
            navigationTabCoordinator.setSheetCoordinator(coordinator) {
                confirm()
            }
            
            navigationTabCoordinator.setSheetCoordinator(nil)
        }
    }
    
    @Test
    mutating func fullScreenCoverDismissalCallback() async {
        let coordinator = SomeTestCoordinator()
        await confirmation("Wait for callback") { confirm in
            navigationTabCoordinator.setFullScreenCoverCoordinator(coordinator) {
                confirm()
            }
            
            navigationTabCoordinator.setFullScreenCoverCoordinator(nil)
        }
    }
    
    @Test
    mutating func overlayDismissalCallback() async {
        let overlayCoordinator = SomeTestCoordinator()
        
        await confirmation("Wait for callback") { confirm in
            navigationTabCoordinator.setOverlayCoordinator(overlayCoordinator) {
                confirm()
            }
            
            navigationTabCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    @Test
    mutating func overlayDismissalCallbackWhenChangingMode() async throws {
        let overlayCoordinator = SomeTestCoordinator()
        
        try await confirmation("Callback should not be called when just changing mode",
                               expectedCount: 0) { confirmation in
            navigationTabCoordinator.setOverlayCoordinator(overlayCoordinator) {
                confirmation()
            }
            
            navigationTabCoordinator.setOverlayPresentationMode(.minimized)
            try await Task.sleep(for: .seconds(1))
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
    
    private func assertCoordinatorsEqual(_ lhs: [CoordinatorProtocol], _ rhs: [CoordinatorProtocol]) {
        guard lhs.count == rhs.count else {
            Issue.record("Coordinators are not the same")
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
