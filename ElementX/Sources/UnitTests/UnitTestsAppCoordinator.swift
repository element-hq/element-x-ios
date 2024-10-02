//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class UnitTestsAppCoordinator: AppCoordinatorProtocol {
    let windowManager: SecureWindowManagerProtocol
    
    init(appDelegate: AppDelegate) {
        windowManager = WindowManager(appDelegate: appDelegate)
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorControllerMock.default)
        
        AppSettings.configureWithSuiteName("io.element.elementx.unittests")
        AppSettings.resetAllSettings()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock())
        
        let analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: ServiceLocator.shared.settings))
    }
    
    func start() { }
    
    func toPresentable() -> AnyView {
        AnyView(ProgressView("Running Unit Tests"))
    }
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        fatalError("Not implemented.")
    }
    
    func handleUserActivity(_ activity: NSUserActivity) {
        fatalError("Not implemented.")
    }
}
