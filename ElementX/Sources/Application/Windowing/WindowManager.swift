//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

class WindowManager: SecureWindowManagerProtocol {
    private let appDelegate: AppDelegate
    weak var windowScene: UIWindowScene?
    weak var delegate: SecureWindowManagerDelegate?
    
    private(set) var mainWindow: UIWindow!
    private(set) var overlayWindow: UIWindow!
    private(set) var globalSearchWindow: UIWindow!
    private(set) var alternateWindow: UIWindow!
        
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, globalSearchWindow, alternateWindow]
    }
    
    // periphery:ignore - auto cancels when reassigned
    /// The task used to switch windows, so that we don't get stuck in the wrong state with a quick switch.
    @CancellableTask private var switchTask: Task<Void, Error>?
    /// A duration that allows window switching to wait a couple of frames to avoid a transition through black.
    private let windowHideDelay = Duration.milliseconds(33)
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func configure(with windowScene: UIWindowScene) {
        self.windowScene = windowScene
        mainWindow = windowScene.keyWindow
        mainWindow.tintColor = .compound.textActionPrimary
        
        overlayWindow = PassthroughWindow(windowScene: windowScene)
        overlayWindow.tintColor = .compound.textActionPrimary
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false
        
        globalSearchWindow = UIWindow(windowScene: windowScene)
        globalSearchWindow.tintColor = .compound.textActionPrimary
        globalSearchWindow.backgroundColor = .clear
        globalSearchWindow.isHidden = true
        
        alternateWindow = UIWindow(windowScene: windowScene)
        alternateWindow.tintColor = .compound.textActionPrimary
        
        delegate?.windowManagerDidConfigureWindows(self)
    }
    
    func switchToMain() {
        mainWindow.isHidden = false
        overlayWindow.isHidden = false
        
        mainWindow.makeKey()
        
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
        
        hideGlobalSearch()
        
        // alternateWindow.isHidden = false cannot got inside the Task otherwise the timing
        // is poor when you lock the phone - you briefly see the main window for a few
        // frames after you've unlocked the phone and then the placeholder animates in.
        switchTask = Task {
            // Delay hiding to make sure the alternate window is visible.
            try await Task.sleep(for: windowHideDelay)
            
            mainWindow.isHidden = true
            overlayWindow.isHidden = true
            globalSearchWindow.isHidden = true
        }
    }
    
    func showGlobalSearch() {
        guard alternateWindow.isHidden else {
            return
        }
        
        globalSearchWindow.isHidden = false
        globalSearchWindow.makeKey()
    }
    
    func hideGlobalSearch() {
        guard alternateWindow.isHidden else {
            return
        }
        
        globalSearchWindow.isHidden = true
        mainWindow.makeKey()
    }
    
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        appDelegate.orientationLock = orientation
    }
}

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        
        guard let rootViewController else {
            return nil
        }
        
        guard hitView != self else {
            return nil
        }
        
        // If the returned view is the `UIHostingController`'s view, ignore.
        return rootViewController.view == hitView ? nil : hitView
    }
}
