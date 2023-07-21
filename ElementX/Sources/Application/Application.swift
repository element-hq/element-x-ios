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
    private let appCoordinator: AppCoordinatorProtocol

    init() {
        if Tests.isRunningUITests {
            appCoordinator = UITestsAppCoordinator()
        } else if Tests.isRunningUnitTests {
            appCoordinator = UnitTestsAppCoordinator()
        } else {
            appCoordinator = AppCoordinator()
        }
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.toPresentable()
                .statusBarHidden(shouldHideStatusBar)
                .introspect(.window, on: .iOS(.v16)) { window in
                    // Workaround for SwiftUI not consistently applying the tint colour to Alerts/Confirmation Dialogs.
                    window.tintColor = UIColor(named: "colorGray1400",
                                               in: Bundle(identifier: "CompoundDesignTokens-CompoundDesignTokens-resources"),
                                               compatibleWith: nil)
                }
                .task {
                    appCoordinator.start()
                }
        }
    }
    
    private var shouldHideStatusBar: Bool {
        Tests.isRunningUITests
    }
}
