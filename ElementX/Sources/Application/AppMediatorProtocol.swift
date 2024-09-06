//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

// sourcery: AutoMockable
@MainActor
protocol AppMediatorProtocol {
    var windowManager: WindowManagerProtocol { get }
    var networkMonitor: NetworkMonitorProtocol { get }
    
    var appState: UIApplication.State { get }
    
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
    
    func open(_ url: URL)
    
    func openAppSettings()
    
    func setIdleTimerDisabled(_ disabled: Bool)
    
    func requestAuthorizationIfNeeded() async -> Bool
}

extension UIApplication.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}

extension UIUserInterfaceActiveAppearance: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}
