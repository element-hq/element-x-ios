//
// Copyright 2023 New Vector Ltd
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

import Combine
import SwiftUI

protocol WindowManagerDelegate: AnyObject {
    /// The window manager has configured its windows.
    func windowManagerDidConfigureWindows(_ windowManager: WindowManager)
}

@MainActor
/// A window manager that supports switching between a main app window with an overlay and
/// an alternate window to switch contexts whilst also preserving the main view hierarchy.
/// Heavily inspired by https://www.fivestars.blog/articles/swiftui-windows/
class WindowManager {
    weak var delegate: WindowManagerDelegate?
    
    /// The app's main window (we only support a single scene).
    private(set) var mainWindow: UIWindow!
    /// Presented on top of the main window, to display e.g. user indicators.
    private(set) var overlayWindow: UIWindow!
    /// A secondary window that can be presented instead of the main/overlay window combo.
    private(set) var alternateWindow: UIWindow!
    
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, alternateWindow]
    }
    
    /// Configures the window manager to operate on the supplied scene.
    func configure(with windowScene: UIWindowScene) {
        mainWindow = windowScene.keyWindow
        mainWindow.tintColor = .compound.textActionPrimary
        
        overlayWindow = PassthroughWindow(windowScene: windowScene)
        overlayWindow.tintColor = .compound.textActionPrimary
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false
        
        alternateWindow = UIWindow(windowScene: windowScene)
        alternateWindow.tintColor = .compound.textActionPrimary
        
        delegate?.windowManagerDidConfigureWindows(self)
    }
    
    /// Shows the main and overlay window combo, hiding the alternate window.
    func switchToMain() {
        mainWindow.isHidden = false
        overlayWindow.isHidden = false
        alternateWindow.isHidden = true
    }
    
    /// Shows the alternate window, hiding the main and overlay combo.
    func switchToAlternate() {
        alternateWindow.isHidden = false
        overlayWindow.isHidden = true
        mainWindow.isHidden = true
        
        // We don't know what route the app will use when returning back
        // to the main window, so end any editing operation now to avoid
        // e.g. the keyboard being displayed on top of a call sheet.
        mainWindow.endEditing(true)
    }
}

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        
        // If the returned view is the `UIHostingController`'s view, ignore.
        return rootViewController?.view == hitView ? nil : hitView
    }
}
