//
// Copyright 2024 New Vector Ltd
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

import SwiftUI

protocol WindowManagerDelegate: AnyObject {
    /// The window manager has configured its windows.
    func windowManagerDidConfigureWindows(_ windowManager: WindowManagerProtocol)
}

@MainActor
/// A window manager that supports switching between a main app window with an overlay and
/// an alternate window to switch contexts whilst also preserving the main view hierarchy.
/// Heavily inspired by https://www.fivestars.blog/articles/swiftui-windows/
protocol WindowManagerProtocol: AnyObject, OrientationManagerProtocol {
    var delegate: WindowManagerDelegate? { get set }
    
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
    
    /// Configures the window manager to operate on the supplied scene.
    func configure(with windowScene: UIWindowScene)
    
    /// Shows the main and overlay window combo, hiding the alternate window.
    func switchToMain()
    
    /// Shows the alternate window, hiding the main and overlay combo.
    func switchToAlternate()
    
    /// Makes the global search window key. Used to get automatic text field focus.
    func switchToGlobalSearch()
}
