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
    private let appMediator: AppMediatorProtocol
    private var reusableTasks = NSMapTable<NSString, UIKitBackgroundTask>(keyOptions: .strongMemory, valueOptions: .weakMemory)
    
    init(appMediator: AppMediatorProtocol) {
        self.appMediator = appMediator
    }

    func startBackgroundTask(withName name: String,
                             isReusable: Bool,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskProtocol? {
        if shouldAvoidStartingNewTasks() {
            MXLog.error("Do not start background task: \(name), as not enough time exists")
            //  call expiration handler immediately
            expirationHandler?()
            return nil
        }
        var created = false
        var result: BackgroundTaskProtocol?

        if isReusable {
            if let oldTask = reusableTasks.object(forKey: name as NSString), oldTask.isRunning {
                oldTask.reuse()
                result = oldTask
            } else {
                if let newTask = UIKitBackgroundTask(name: name,
                                                     isReusable: isReusable,
                                                     appMediator: appMediator,
                                                     expirationHandler: { [weak self] task in
                                                         guard let self else { return }
                                                         self.reusableTasks.removeObject(forKey: task.name as NSString)
                                                         expirationHandler?()
                                                     }) {
                    created = true
                    reusableTasks.setObject(newTask, forKey: name as NSString)
                    result = newTask
                }
            }
        } else {
            if let newTask = UIKitBackgroundTask(name: name,
                                                 isReusable: isReusable,
                                                 appMediator: appMediator,
                                                 expirationHandler: { _ in
                                                     expirationHandler?()
                                                 }) {
                result = newTask
                created = true
            }
        }

        let appState = appMediator.appState
        let remainingTime = readableBackgroundTimeRemaining(appMediator.backgroundTimeRemaining)

        MXLog.verbose("Background task \(name) \(created ? "started" : "reused") with app state: \(appState) and estimated background time remaining: \(remainingTime)")

        return result
    }

    private func readableBackgroundTimeRemaining(_ backgroundTimeRemaining: TimeInterval) -> String {
        if backgroundTimeRemaining == .greatestFiniteMagnitude {
            return "undetermined"
        } else {
            return String(format: "%.0f seconds", backgroundTimeRemaining)
        }
    }

    private func shouldAvoidStartingNewTasks() -> Bool {
        if appMediator.appState == .background,
           appMediator.backgroundTimeRemaining < .backgroundTimeRemainingThresholdToStartTasks {
            return true
        }
        return false
    }
}

private extension TimeInterval {
    static let backgroundTimeRemainingThresholdToStartTasks: TimeInterval = 5
}
