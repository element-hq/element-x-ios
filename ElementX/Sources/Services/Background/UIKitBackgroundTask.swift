//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        Date().timeIntervalSince(startDate) * 1000
    }

    private let application: ApplicationProtocol
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var useCounter = 0
    private let startDate = Date()

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
            MXLog.verbose("[UIKitBackgroundTask] Do not start background task: \(name), as OS declined")
            //  call expiration handler immediately
            expirationHandler?(self)
            return nil
        }

        if isReusable {
            //  creation itself is a use
            reuse()
        }

        MXLog.verbose("[UIKitBackgroundTask] Start background task #\(identifier.rawValue) - \(name)")
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
            MXLog.verbose("[UIKitBackgroundTask] End background task #\(identifier.rawValue) - \(name) after \(readableElapsedTime)")

            application.endBackgroundTask(identifier)
            identifier = .invalid
        }
    }

    private var readableElapsedTime: String {
        String(format: "%.3fms", elapsedTime)
    }
}
