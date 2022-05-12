//
//  UITestsAppCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 29/04/2022.
//  Copyright © 2022 element.io. All rights reserved.
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
        
        let screens = mockScreens()
        let rootView = UITestsRootView(mockScreens: screens) { id in
            guard let screen = screens.filter({ $0.id == id }).first else {
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
        [MockScreen(id: "Login screen", coordinator: LoginScreenCoordinator(parameters: .init())),
        MockScreen(id: "Simple Screen - Regular", coordinator: TemplateSimpleScreenCoordinator(parameters: .init(promptType: .regular))),
        MockScreen(id: "Simple Screen - Upgrade", coordinator: TemplateSimpleScreenCoordinator(parameters: .init(promptType: .upgrade)))]
    }
}

struct MockScreen: Identifiable {
    let id: String
    let coordinator: Presentable
}
