//
// Copyright 2022 New Vector Ltd
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

@main
struct Application: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var applicationDelegate
    @Environment(\.openURL) private var openURL
    private var appCoordinator: AppCoordinatorProtocol!

    init() {
        if ProcessInfo.isRunningUITests {
            appCoordinator = UITestsAppCoordinator()
        } else if ProcessInfo.isRunningUnitTests {
            appCoordinator = UnitTestsAppCoordinator()
        } else {
            appCoordinator = AppCoordinator(appDelegate: applicationDelegate)
        }
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.toPresentable()
                .statusBarHidden(shouldHideStatusBar)
                .environment(\.openURL, OpenURLAction { url in
                    if appCoordinator.handleDeepLink(url) {
                        return .handled
                    }

                    return .systemAction
                })
                .onOpenURL {
                    if !appCoordinator.handleDeepLink($0) {
                        openURL($0)
                    }
                }
                .introspect(.window, on: .supportedVersions) { window in
                    // Workaround for SwiftUI not consistently applying the tint colour to Alerts/Confirmation Dialogs.
                    window.tintColor = .compound.textActionPrimary
                }
                .task {
                    appCoordinator.start()
                }
        }
    }

    private var shouldHideStatusBar: Bool {
        ProcessInfo.isRunningUITests
    }
}
