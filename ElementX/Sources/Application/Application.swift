//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

@main
struct Application: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openURL) private var openURL
    
    private var appCoordinator: AppCoordinatorProtocol!

    init() {
        if ProcessInfo.isRunningUITests {
            appCoordinator = UITestsAppCoordinator(appDelegate: appDelegate)
        } else if ProcessInfo.isRunningUnitTests {
            appCoordinator = UnitTestsAppCoordinator(appDelegate: appDelegate)
        } else if ProcessInfo.isRunningAccessibilityTests {
            appCoordinator = AccessibilityTestsAppCoordinator(appDelegate: appDelegate)
        } else {
            appCoordinator = AppCoordinator(appDelegate: appDelegate)
        }
        
        SceneDelegate.windowManager = appCoordinator.windowManager
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.toPresentable()
                .statusBarHidden(shouldHideStatusBar)
                .overlay(alignment: .top) {
                    if #available(iOS 26, *), ProcessInfo.processInfo.isiOSAppOnMac {
                        // Fake an old-school titlebar to reduce the "floaty-ness" of everything with liquid glass.
                        Divider().ignoresSafeArea()
                    }
                }
                .environment(\.openURL, OpenURLAction { url in
                    if appCoordinator.handleDeepLink(url, isExternalURL: false) {
                        return .handled
                    }
                    
                    if appCoordinator.handlePotentialPhishingAttempt(url: url, openURLAction: { url in
                        openURL(url, isExternalURL: false)
                    }) {
                        return .handled
                    }

                    return .systemAction
                })
                .onOpenURL { url in
                    openURL(url, isExternalURL: true)
                }
                .onContinueUserActivity("INStartVideoCallIntent") { userActivity in
                    // `INStartVideoCallIntent` is to be replaced with `INStartCallIntent`
                    // but calls from Recents still send it ¯\_(ツ)_/¯
                    appCoordinator.handleUserActivity(userActivity)
                }
                .task {
                    appCoordinator.start()
                }
        }
    }
    
    // MARK: - Private
    
    private func openURL(_ url: URL, isExternalURL: Bool) {
        if !appCoordinator.handleDeepLink(url, isExternalURL: isExternalURL) {
            openURLInSystemBrowser(url)
        }
    }

    /// Hide the status bar so it doesn't interfere with the screenshot tests
    private var shouldHideStatusBar: Bool {
        ProcessInfo.isRunningUITests
    }
    
    /// https://github.com/element-hq/element-x-ios/issues/1824
    /// Avoid opening universal links in other app variants and infinite loops between them
    private func openURLInSystemBrowser(_ originalURL: URL) {
        guard var urlComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: true) else {
            openURL(originalURL)
            return
        }
        
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(.init(name: "no_universal_links", value: "true"))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            openURL(originalURL)
            return
        }
        
        openURL(url)
    }
}
