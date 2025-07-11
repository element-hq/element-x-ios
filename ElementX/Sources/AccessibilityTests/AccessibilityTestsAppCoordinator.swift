//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI
import UIKit

class AccessibilityTestsAppCoordinator: AppCoordinatorProtocol {
    var windowManager: any SecureWindowManagerProtocol
        
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        fatalError("Not implemented")
    }
    
    func handlePotentialPhishingAttempt(url: URL, openURLAction: @escaping (URL) -> Void) -> Bool {
        fatalError("Not implemented")
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        fatalError("Not implemented")
    }
    
    private var navigationRootCoordinator: NavigationRootCoordinator
    
    init(appDelegate: AppDelegate) {
        windowManager = WindowManager(appDelegate: appDelegate)
        // disabling View animations
        UIView.setAnimationsEnabled(false)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        MXLog.configure(currentTarget: "accessibility-tests")
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.accessibilitytests")
        AppSettings.resetAllSettings()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock(.init()))
        
        let analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: ServiceLocator.shared.settings))
    }
    
    func start() {
        guard let screenID = ProcessInfo.accessibilityViewID else { fatalError("Unable to launch with unknown screen.") }
    }
    
    func toPresentable() -> AnyView {
        HomeScreen_Previews._allPreviews.enumerated().map(\.1).first!.content
    }
}
    