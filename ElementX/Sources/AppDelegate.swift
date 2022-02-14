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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        appCoordinator = AppCoordinator()
        appCoordinator.start()
        return true
    }
}
