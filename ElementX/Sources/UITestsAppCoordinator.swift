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
        [
            MockScreen(id: "Login screen", coordinator: LoginScreenCoordinator(parameters: .init())),
            MockScreen(id: "Simple Screen - Regular", coordinator: TemplateSimpleScreenCoordinator(parameters: .init(promptType: .regular))),
            MockScreen(id: "Simple Screen - Upgrade", coordinator: TemplateSimpleScreenCoordinator(parameters: .init(promptType: .upgrade))),
            MockScreen(id: "Settings screen", coordinator: SettingsCoordinator(parameters: .init(navigationRouter: NavigationRouter(navigationController: UINavigationController()), bugReportService: MockBugReportService()))),
            MockScreen(id: "Bug report screen", coordinator: BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(), screenshot: nil))),
            MockScreen(id: "Bug report screen with screenshot", coordinator: BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(), screenshot: Asset.Images.appLogo.image))),
            MockScreen(id: "Splash Screen", coordinator: SplashScreenCoordinator())
        ]
    }
}

struct MockScreen: Identifiable {
    let id: String
    let coordinator: Presentable
}
