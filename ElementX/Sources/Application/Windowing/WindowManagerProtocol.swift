//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

protocol SecureWindowManagerDelegate: AnyObject {
    /// The window manager has configured its windows.
    func windowManagerDidConfigureWindows(_ windowManager: SecureWindowManagerProtocol)
}

@MainActor
protocol SecureWindowManagerProtocol: WindowManagerProtocol {
    var delegate: SecureWindowManagerDelegate? { get set }
    
    /// Configures the window manager to operate on the supplied scene.
    func configure(with windowScene: UIWindowScene)
    
    /// Shows the main and overlay window combo, hiding the alternate window.
    func switchToMain()
    
    /// Shows the alternate window, hiding the main and overlay combo.
    func switchToAlternate()
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
}

// sourcery: AutoMockable
extension WindowManagerProtocol { }
