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
        let rootView = UITestsRootView(mockCoordinators: screens) { id in
            guard let coordinator = screens.filter({ $0.id == id }).first else {
                fatalError()
            }
            
            self.mainNavigationController.pushViewController(coordinator.coordinator.toPresentable(), animated: true)
        }
        
        mainNavigationController.setViewControllers([UIHostingController(rootView: rootView)], animated: false)
    }
    
    func start() {
        window.makeKeyAndVisible()
    }
    
    private func mockScreens() -> [MockScreens] {
        [MockScreens(id: "Login screen", coordinator: LoginScreenCoordinator(parameters: .init()))]
    }
}

struct MockScreens: Identifiable {
    let id: String
    let coordinator: Presentable
}
