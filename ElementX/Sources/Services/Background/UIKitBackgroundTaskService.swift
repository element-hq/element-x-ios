//
//  UIKitBackgroundTaskService.swift
//  ElementX
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
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
            MXLog.debug("[UIKitBackgroundTaskService] Do not start background task: \(name). Application is nil")
            return nil
        }

        if avoidStartingNewTasks(for: application) {
            MXLog.debug("[UIKitBackgroundTaskService] Do not start background task: \(name), as not enough time exists")
            //  call expiration handler immediately
            expirationHandler?()
            return nil
        }
        var created: Bool = false
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
            result = UIKitBackgroundTask(name: name,
                                         isReusable: isReusable,
                                         application: application) { _ in
                expirationHandler?()
            }
        }

        let appState = application.applicationState
        let remainingTime = readableBackgroundTimeRemaining(application.backgroundTimeRemaining)

        MXLog.debug("[UIKitBackgroundTaskService] Background task \(name) \(created ? "started" : "reused") with app state: \(appState) and estimated background time remaining: \(remainingTime)")

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
        if application.applicationState == .background
            && application.backgroundTimeRemaining < .backgroundTimeRemainingThresholdToStartTasks {
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
