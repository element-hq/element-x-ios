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
    private let navigationController: NavigationController
    private let applicationCoordinator: CoordinatorProtocol
        
    init() {
        navigationController = NavigationController()
        
        if Tests.isRunningUITests {
            applicationCoordinator = UITestsAppCoordinator(navigationController: navigationController)
        } else {
            applicationCoordinator = AppCoordinator(navigationController: navigationController)
        }
        
        navigationController.setRootCoordinator(applicationCoordinator)
    }

    var body: some Scene {
        WindowGroup {
            if Tests.isRunningUnitTests {
                EmptyView()
            } else {
                navigationController
                    .toPresentable()
                    .tint(.element.accent)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        //  use `en` as fallback language
        Bundle.elementFallbackLanguage = "en"

        return true
    }
}
