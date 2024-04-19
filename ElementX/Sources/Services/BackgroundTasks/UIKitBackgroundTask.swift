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

    private let appMediator: AppMediatorProtocol
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var useCounter = 0
    private let startDate = Date()

    init?(name: String,
          isReusable: Bool,
          appMediator: AppMediatorProtocol,
          expirationHandler: BackgroundTaskExpirationHandler?) {
        self.name = name
        self.isReusable = isReusable
        self.appMediator = appMediator
        self.expirationHandler = expirationHandler

        identifier = appMediator.beginBackgroundTask(withName: name) { [weak self] in
            guard let self else { return }
            self.stop()
            self.expirationHandler?(self)
        }

        if identifier == .invalid {
            MXLog.error("Do not start background task: \(name), as OS declined")
            expirationHandler?(self)
            return nil
        }

        if isReusable {
            reuse()
        }

        MXLog.verbose("Start background task #\(identifier.rawValue) - \(name)")
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
            MXLog.verbose("End background task #\(identifier.rawValue) - \(name) after \(readableElapsedTime)")

            appMediator.endBackgroundTask(identifier)
            identifier = .invalid
        }
    }

    private var readableElapsedTime: String {
        String(format: "%.3fms", elapsedTime)
    }
}
