//
//  AppDelegate.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var appCoordinator: Coordinator = Tests.isRunningUITests ? UITestsAppCoordinator() : AppCoordinator()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        //  use `en` as fallback language
        Bundle.elementFallbackLanguage = "en"

        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if Tests.isRunningUnitTests {
            return true
        }
        
        appCoordinator.start()
        
        return true
    }
}
