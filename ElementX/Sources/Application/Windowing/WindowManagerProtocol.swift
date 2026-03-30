//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum WindowManagerWindowType: Hashable, Codable {
    case room(roomID: String)
    case settings
}

protocol SecureWindowManagerDelegate: AnyObject {
    /// The window manager has configured its windows.
    func windowManagerDidConfigureWindows(_ windowManager: SecureWindowManagerProtocol)
}

@MainActor
protocol SecureWindowManagerProtocol: WindowManagerProtocol {
    var delegate: SecureWindowManagerDelegate? { get set }
    
    /// Configures the window manager to operate on the supplied scene.
    func configure(withScene scene: UIWindowScene, session: UISceneSession)
    
    func configure(withOpenWinddowAction openWindowAction: OpenWindowAction, dismissWindowAction: DismissWindowAction)
    
    func handleRoute(_ appRoute: AppRoute, windowType: WindowManagerWindowType)
    
    /// Shows the main and overlay window combo, hiding the alternate window.
    func switchToMain()
    
    /// Shows the alternate window, hiding the main and overlay combo.
    func switchToAlternate()
    
    // MARK: - Auxiliary window support
    
    /// Used by the Application to retrieve the root view for an auxiliary window
    func windowForType(_ type: WindowManagerWindowType) -> AnyView
}

/// A window manager that supports switching between a main app window with an overlay and
/// an alternate window to switch contexts whilst also preserving the main view hierarchy.
/// Heavily inspired by https://www.fivestars.blog/articles/swiftui-windows/
protocol WindowManagerProtocol: AnyObject, OrientationManagerProtocol {
    /// The app's main window (we only support a single scene).
    var mainWindow: UIWindow! { get }
    /// Presented on top of the main window, to display e.g. user indicators.
    var overlayWindow: UIWindow! { get }
    /// A window layered on top of the main one. Used by the global search function
    var globalSearchWindow: UIWindow! { get }
    /// A secondary window that can be presented instead of the main/overlay window combo.
    var alternateWindow: UIWindow! { get }
    
    /// All the windows being managed
    var windows: [UIWindow] { get }
    
    /// Makes the global search window key. Used to get automatic text field focus.
    func showGlobalSearch()
    
    func hideGlobalSearch()
    
    // MARK: - Auxiliary window support
    
    /// Register a coordinator and it's respective flow (if any) within the WindowManager which in turn
    /// invokes the Application's `OpenWindowAction`
    func registerCoordinator(_ coordinator: CoordinatorProtocol,
                             flowCoordinator: FlowCoordinatorProtocol?,
                             forWindowType type: WindowManagerWindowType)
    
    /// Closes any window previously opened by registering a coordinator
    func closeAllAuxiliaryWindows()
    
    /// Closes a previously opened window for the given type.
    func closeAuxiliaryWindow(forType type: WindowManagerWindowType)
}

// sourcery: AutoMockable
extension WindowManagerProtocol { }
