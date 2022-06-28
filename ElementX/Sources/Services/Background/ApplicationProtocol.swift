//
//  ApplicationProtocol.swift
//  ElementX
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

protocol ApplicationProtocol {
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)

    var backgroundTimeRemaining: TimeInterval { get }

    var applicationState: UIApplication.State { get }
}

extension UIApplication: ApplicationProtocol {}
