//
//  AppDelegate.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var appCoordinator: AppCoordinator!

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        //  fixme: Use `Bundle.elementLanguage = ".."` when we have the functionality
        //  use `en` as fallback language
        Bundle.elementFallbackLanguage = "en"

        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if isRunningUnitTests {
            return true
        }
        
        if isRunningUITests {
            // Bootstrap a different version of the application
            return true
        }
        
        appCoordinator = AppCoordinator()
        appCoordinator.start()
        return true
    }
    
    private var isRunningUnitTests: Bool {
        #if DEBUG
            ProcessInfo.processInfo.environment["IS_RUNNING_UNIT_TESTS"] == "1"
        #else
            false
        #endif
    }
    
    private var isRunningUITests: Bool {
        #if DEBUG
            ProcessInfo.processInfo.environment["IS_RUNNING_UI_TESTS"] == "1"
        #else
            false
        #endif
    }
}
