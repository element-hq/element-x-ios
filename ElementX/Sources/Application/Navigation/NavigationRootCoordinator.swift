//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class NavigationRootCoordinator: ObservableObject, CoordinatorProtocol, CustomStringConvertible {
    @Published fileprivate var rootModule: NavigationModule? {
        didSet {
            if let oldValue {
                oldValue.tearDown()
            }
            
            if let rootModule {
                logPresentationChange("Set root", rootModule)
                rootModule.coordinator?.start()
            }
        }
    }
    
    /// The currently displayed coordinator
    var rootCoordinator: (any CoordinatorProtocol)? {
        rootModule?.coordinator
    }
    
    @Published fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.tearDown()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator?.start()
            }
        }
    }
    
    // periphery:ignore - might be useful to have
    // The currently presented sheet coordinator
    // Sheets will be presented through the NavigationSplitCoordinator if provided
    var sheetCoordinator: (any CoordinatorProtocol)? {
        sheetModule?.coordinator
    }
    
    @Published fileprivate var overlayModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove overlay", oldValue)
                oldValue.tearDown()
            }
            
            if let overlayModule {
                logPresentationChange("Set overlay", overlayModule)
                overlayModule.coordinator?.start()
            }
        }
    }
    
    /// The currently displayed overlay coordinator
    var overlayCoordinator: (any CoordinatorProtocol)? {
        overlayModule?.coordinator
    }
    
    /// Sets or replaces the presented coordinator
    /// - Parameter coordinator: the coordinator to display
    func setRootCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        
        withTransaction(transaction) {
            guard let coordinator else {
                rootModule = nil
                return
            }
            
            rootModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        if sheetModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Present an overlay on top of the split view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when the overlay has been dismissed, programatically or otherwise
    func setOverlayCoordinator(_ coordinator: (any CoordinatorProtocol)?,
                               animated: Bool = true,
                               dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            overlayModule = nil
            return
        }
        
        if overlayModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            overlayModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
        
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        AnyView(NavigationRootCoordinatorView(rootCoordinator: self))
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        if let rootCoordinator = rootModule?.coordinator {
            return "NavigationRootCoordinator(\(rootCoordinator)"
        } else {
            return "NavigationRootCoordinator(Empty)"
        }
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        if let coordinator = module.coordinator {
            MXLog.info("\(self) \(change): \(coordinator)")
        }
    }
}

private struct NavigationRootCoordinatorView: View {
    @ObservedObject var rootCoordinator: NavigationRootCoordinator
    
    var body: some View {
        ZStack {
            rootCoordinator.rootModule?.coordinator?.toPresentable()
        }
        .animation(.elementDefault, value: rootCoordinator.rootModule)
        .sheet(item: $rootCoordinator.sheetModule) { module in
            module.coordinator?.toPresentable()
        }
        .overlay {
            Group {
                if let coordinator = rootCoordinator.overlayModule?.coordinator {
                    coordinator.toPresentable()
                        .transition(.opacity)
                }
            }
            .animation(.elementDefault, value: rootCoordinator.overlayModule)
        }
    }
}
