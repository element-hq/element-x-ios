//
//  UIKitBackgroundTask.swift
//  ElementX
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

/// UIKitBackgroundTask is a concrete implementation of BackgroundTaskProtocol using UIApplication background task.
class UIKitBackgroundTask: BackgroundTaskProtocol {
    let name: String
    var isRunning: Bool {
        identifier != .invalid
    }
    let isReusable: Bool
    let expirationHandler: BackgroundTaskExpirationHandler?
    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startDate) * 1000
    }

    private let application: ApplicationProtocol
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var useCounter: Int = 0
    private let startDate: Date = Date()

    /// Initializes and starts a new background task
    /// - Parameters:
    ///   - name: name
    ///   - isReusable: flag indicating the task is reusable
    ///   - application: application instance
    ///   - expirationHandler: expiration handler
    init?(name: String,
          isReusable: Bool,
          application: ApplicationProtocol,
          expirationHandler: BackgroundTaskExpirationHandler?) {
        self.name = name
        self.isReusable = isReusable
        self.application = application
        self.expirationHandler = expirationHandler

        // attempt to start
        identifier = application.beginBackgroundTask(withName: name) { [weak self] in
            guard let self = self else { return }
            self.expirationHandler?(self)
        }

        if identifier == .invalid {
            MXLog.debug("[UIKitBackgroundTask] Do not start background task: \(name), as OS declined")
            //  call expiration handler immediately
            expirationHandler?(self)
            return nil
        }

        if isReusable {
            //  creation itself is a use
            reuse()
        }

        MXLog.debug("[UIKitBackgroundTask] Start background task #\(identifier.rawValue) - \(name)")
    }

    func reuse() {
        guard isReusable else {
            return
        }
        useCounter += 1
    }

    func stop() {
        if isReusable {
            useCounter -= 1
            if useCounter <= 0 {
                endTask()
            }
        } else {
            endTask()
        }
    }

    private func endTask() {
        if identifier != .invalid {
            MXLog.debug("[UIKitBackgroundTask] End background task #\(identifier.rawValue) - \(name) after \(readableElapsedTime)")

            application.endBackgroundTask(identifier)
            identifier = .invalid
        }
    }

    private var readableElapsedTime: String {
        String(format: "%.3fms", elapsedTime)
    }
}
