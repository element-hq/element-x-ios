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

/// /// UIKitBackgroundTaskService is a concrete implementation of BackgroundTaskServiceProtocol using a given `ApplicationProtocol`  instance.
class UIKitBackgroundTaskService: BackgroundTaskServiceProtocol {
    private let application: ApplicationProtocol?
    private var reusableTasks: WeakDictionary<String, UIKitBackgroundTask> = WeakDictionary()

    /// Initializer
    /// - Parameter application: application instance to use. Defaults to `UIApplication.extensionSafeShared`.
    init(withApplication application: ApplicationProtocol? = UIApplication.extensionSafeShared) {
        self.application = application
    }

    func startBackgroundTask(withName name: String,
                             isReusable: Bool,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskProtocol? {
        guard let application = application else {
            MXLog.verbose("[UIKitBackgroundTaskService] Do not start background task: \(name). Application is nil")
            return nil
        }

        if avoidStartingNewTasks(for: application) {
            MXLog.verbose("[UIKitBackgroundTaskService] Do not start background task: \(name), as not enough time exists")
            //  call expiration handler immediately
            expirationHandler?()
            return nil
        }
        var created = false
        var result: BackgroundTaskProtocol?

        if isReusable {
            if let oldTask = reusableTasks[name], oldTask.isRunning {
                oldTask.reuse()
                result = oldTask
            } else {
                if let newTask = UIKitBackgroundTask(name: name,
                                                     isReusable: isReusable,
                                                     application: application,
                                                     expirationHandler: { [weak self] task in
                                                         guard let self = self else { return }
                                                         self.reusableTasks[task.name] = nil
                                                         expirationHandler?()
                                                     }) {
                    created = true
                    reusableTasks[name] = newTask
                    result = newTask
                }
            }
        } else {
            if let newTask = UIKitBackgroundTask(name: name,
                                                 isReusable: isReusable,
                                                 application: application,
                                                 expirationHandler: { _ in
                                                     expirationHandler?()
                                                 }) {
                result = newTask
                created = true
            }
        }

        let appState = application.applicationState
        let remainingTime = readableBackgroundTimeRemaining(application.backgroundTimeRemaining)

        MXLog.verbose("[UIKitBackgroundTaskService] Background task \(name) \(created ? "started" : "reused") with app state: \(appState) and estimated background time remaining: \(remainingTime)")

        return result
    }

    private func readableBackgroundTimeRemaining(_ backgroundTimeRemaining: TimeInterval) -> String {
        if backgroundTimeRemaining == .greatestFiniteMagnitude {
            return "undetermined"
        } else {
            return String(format: "%.0f seconds", backgroundTimeRemaining)
        }
    }

    private func avoidStartingNewTasks(for application: ApplicationProtocol) -> Bool {
        if application.applicationState == .background,
           application.backgroundTimeRemaining < .backgroundTimeRemainingThresholdToStartTasks {
            return true
        }
        return false
    }
}

private extension TimeInterval {
    static let backgroundTimeRemainingThresholdToStartTasks: TimeInterval = 5
}

private extension UIApplication {
    /// Application instance extension-safe. Will be `nil` on app extensions.
    static var extensionSafeShared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard Self.responds(to: selector) else { return nil }
        return Self.perform(selector).takeUnretainedValue() as? UIApplication
    }
}

extension UIApplication.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}
