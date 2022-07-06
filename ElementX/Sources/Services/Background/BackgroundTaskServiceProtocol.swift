//
//  BackgroundTaskServiceProtocol.swift
//  ElementX
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

protocol BackgroundTaskServiceProtocol {

    func startBackgroundTask(withName name: String,
                             isReusable: Bool,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskProtocol?

}

extension BackgroundTaskServiceProtocol {

    func startBackgroundTask(withName name: String) -> BackgroundTaskProtocol? {
        startBackgroundTask(withName: name,
                            expirationHandler: nil)
    }

    func startBackgroundTask(withName name: String,
                             isReusable: Bool) -> BackgroundTaskProtocol? {
        startBackgroundTask(withName: name,
                            isReusable: isReusable,
                            expirationHandler: nil)
    }

    func startBackgroundTask(withName name: String,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskProtocol? {
        startBackgroundTask(withName: name,
                            isReusable: false,
                            expirationHandler: expirationHandler)
    }

}
