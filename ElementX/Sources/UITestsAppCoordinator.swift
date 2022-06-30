//
//  UITestsAppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 29/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import SwiftUI

class UITestsAppCoordinator: Coordinator {
    private let window: UIWindow
    private let mainNavigationController: UINavigationController
    
    var childCoordinators: [Coordinator] = []
    
    init() {
        mainNavigationController = UINavigationController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = mainNavigationController
        window.tintColor = .element.accent
        
        let screens = mockScreens()
        screens.forEach { $0.coordinator.start() }
        
        let rootView = UITestsRootView(mockScreens: screens) { id in
            guard let screen = screens.first(where: { $0.id == id }) else {
                fatalError()
            }
            
            self.mainNavigationController.pushViewController(screen.coordinator.toPresentable(), animated: true)
        }
        
        mainNavigationController.setViewControllers([UIHostingController(rootView: rootView)], animated: false)
    }
    
    func start() {
        window.makeKeyAndVisible()
    }
    
    private func mockScreens() -> [MockScreen] {
        UITestScreenIdentifier.allCases.map { MockScreen(id: $0) }
    }
}

@MainActor
struct MockScreen: Identifiable {
    let id: UITestScreenIdentifier
    var coordinator: Coordinator & Presentable {
        switch id {
        case .login:
            let router = NavigationRouter(navigationController: ElementNavigationController())
            return LoginCoordinator(parameters: .init(navigationRouter: router,
                                                      homeserver: .mockMatrixDotOrg))
        case .loginOIDC:
            let router = NavigationRouter(navigationController: ElementNavigationController())
            return LoginCoordinator(parameters: .init(navigationRouter: router,
                                                      homeserver: .mockOIDC))
        case .loginUnsupported:
            let router = NavigationRouter(navigationController: ElementNavigationController())
            return LoginCoordinator(parameters: .init(navigationRouter: router,
                                                      homeserver: .mockUnsupported))
        case .simpleRegular:
            return TemplateCoordinator(parameters: .init(promptType: .regular))
        case .simpleUpgrade:
            return TemplateCoordinator(parameters: .init(promptType: .upgrade))
        case .settings:
            let router = NavigationRouter(navigationController: ElementNavigationController())
            return SettingsCoordinator(parameters: .init(navigationRouter: router,
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
            let params = RoomScreenCoordinatorParameters(timelineController: MockRoomTimelineController(),
                                                         roomName: "Some room name",
                                                         roomAvatar: nil,
                                                         roomEncryptionBadge: nil)
            return RoomScreenCoordinator(parameters: params)
        case .roomEncryptedWithAvatar:
            let params = RoomScreenCoordinatorParameters(timelineController: MockRoomTimelineController(),
                                                         roomName: "Some room name",
                                                         roomAvatar: Asset.Images.appLogo.image,
                                                         roomEncryptionBadge: Asset.Images.encryptionTrusted.image)
            return RoomScreenCoordinator(parameters: params)
        }
    }
}
