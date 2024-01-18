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

class WindowManager: WindowManagerProtocol {
    weak var windowScene: UIWindowScene?
    weak var delegate: WindowManagerDelegate?
    
    private(set) var mainWindow: UIWindow!
    private(set) var overlayWindow: UIWindow!
    private(set) var alternateWindow: UIWindow!
    
    var orientationLock: UIInterfaceOrientationMask = .all
    
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, alternateWindow]
    }
    
    // periphery:ignore - auto cancels when reassigned
    /// The task used to switch windows, so that we don't get stuck in the wrong state with a quick switch.
    @CancellableTask private var switchTask: Task<Void, Error>?
    /// A duration that allows window switching to wait a couple of frames to avoid a transition through black.
    private let windowHideDelay = Duration.milliseconds(33)
    
    func configure(with windowScene: UIWindowScene) {
        self.windowScene = windowScene
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
    
    func switchToMain() {
        mainWindow.isHidden = false
        overlayWindow.isHidden = false
        
        switchTask = Task {
            // Delay hiding to make sure the main windows are visible.
            try await Task.sleep(for: windowHideDelay)
            
            alternateWindow.isHidden = true
        }
    }
    
    func switchToAlternate() {
        alternateWindow.isHidden = false
        
        // We don't know what route the app will use when returning back
        // to the main window, so end any editing operation now to avoid
        // e.g. the keyboard being displayed on top of a call sheet.
        mainWindow.endEditing(true)
        
        // alternateWindow.isHidden = false cannot got inside the Task otherwise the timing
        // is poor when you lock the phone - you briefly see the main window for a few
        // frames after you've unlocked the phone and then the placeholder animates in.
        switchTask = Task {
            // Delay hiding to make sure the alternate window is visible.
            try await Task.sleep(for: windowHideDelay)
            
            overlayWindow.isHidden = true
            mainWindow.isHidden = true
        }
    }
    
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
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
