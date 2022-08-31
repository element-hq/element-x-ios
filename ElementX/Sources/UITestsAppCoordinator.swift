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
import UIKit

class UITestsAppCoordinator: Coordinator {
    private let window: UIWindow
    private let mainNavigationController: ElementNavigationController
    private let navigationRouter: NavigationRouter
    private var hostingController: UIViewController?
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        mainNavigationController = ElementNavigationController()
        navigationRouter = NavigationRouter(navigationController: mainNavigationController)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        window.tintColor = .element.accent
        
        UIView.setAnimationsEnabled(false)
        
        let screens = mockScreens()
        
        let rootView = UITestsRootView(mockScreens: screens) { id in
            guard let screen = screens.first(where: { $0.id == id }) else {
                fatalError()
            }
            
            screen.coordinator.start()
            self.navigationRouter.setRootModule(screen.coordinator)
        }
        
        let hostingController = UIHostingController(rootView: rootView)
        self.hostingController = hostingController
        
        mainNavigationController.setViewControllers([hostingController], animated: false)
    }
    
    func start() {
        window.makeKeyAndVisible()
    }
    
    private func mockScreens() -> [MockScreen] {
        UITestScreenIdentifier.allCases.map { MockScreen(id: $0, navigationRouter: navigationRouter) }
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestScreenIdentifier
    let navigationRouter: NavigationRouter
    lazy var coordinator: Coordinator & Presentable = {
        switch id {
        case .login:
            return LoginCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                      navigationRouter: navigationRouter))
        case .serverSelection:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                hasModalPresentation: true))
        case .serverSelectionNonModal:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                hasModalPresentation: false))
        case .authenticationFlow:
            return AuthenticationCoordinator(authenticationService: MockAuthenticationServiceProxy(),
                                             navigationRouter: navigationRouter)
        case .simpleRegular:
            return TemplateCoordinator(parameters: .init(promptType: .regular))
        case .simpleUpgrade:
            return TemplateCoordinator(parameters: .init(promptType: .upgrade))
        case .settings:
            return SettingsCoordinator(parameters: .init(navigationRouter: navigationRouter,
                                                         userSession: MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@mock:client.com"),
                                                                                      mediaProvider: MockMediaProvider()),
                                                         bugReportService: MockBugReportService()))
        case .bugReport:
            return BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                          screenshot: nil))
        case .bugReportWithScreenshot:
            return BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                          screenshot: Asset.Images.appLogo.image))
        case .splash:
            return SplashScreenCoordinator()
        case .roomPlainNoAvatar:
            let parameters = RoomScreenCoordinatorParameters(timelineController: MockRoomTimelineController(),
                                                             roomName: "Some room name",
                                                             roomAvatar: nil,
                                                             roomEncryptionBadge: nil)
            return RoomScreenCoordinator(parameters: parameters)
        case .roomEncryptedWithAvatar:
            let parameters = RoomScreenCoordinatorParameters(timelineController: MockRoomTimelineController(),
                                                             roomName: "Some room name",
                                                             roomAvatar: Asset.Images.appLogo.image,
                                                             roomEncryptionBadge: Asset.Images.encryptionTrusted.image)
            return RoomScreenCoordinator(parameters: parameters)
        case .sessionVerification:
            let parameters = SessionVerificationCoordinatorParameters(sessionVerificationControllerProxy: MockSessionVerificationControllerProxy())
            return SessionVerificationCoordinator(parameters: parameters)
        }
    }()
    
    init(id: UITestScreenIdentifier, navigationRouter: NavigationRouter) {
        self.id = id
        self.navigationRouter = navigationRouter
    }
}
