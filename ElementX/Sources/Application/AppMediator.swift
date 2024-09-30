//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation
import UIKit

class AppMediator: AppMediatorProtocol {
    let windowManager: WindowManagerProtocol
    let networkMonitor: NetworkMonitorProtocol
    
    init(windowManager: WindowManagerProtocol, networkMonitor: NetworkMonitorProtocol) {
        self.windowManager = windowManager
        self.networkMonitor = networkMonitor
    }
        
    // UIApplication.State won't update if we store this e.g. in the constructor
    private var application: UIApplication {
        UIApplication.shared
    }

    var appState: UIApplication.State {
        switch application.applicationState {
        case .active:
            windowManager.mainWindow.traitCollection.activeAppearance == .active ? .active : .inactive
        case .inactive:
            .inactive
        case .background:
            .background
        default:
            .inactive
        }
    }
    
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        application.beginBackgroundTask(expirationHandler: handler)
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        application.endBackgroundTask(identifier)
    }
    
    func open(_ url: URL) {
        application.open(url, options: [:], completionHandler: nil)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        open(url)
    }
    
    func setIdleTimerDisabled(_ disabled: Bool) {
        application.isIdleTimerDisabled = disabled
    }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Determine if the user previously authorized camera access.
        if status == .authorized {
            return true
        }
        
        var isAuthorized = false
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        return isAuthorized
    }
}
