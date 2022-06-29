//
//  BackgroundTaskProtocol.swift
//  ElementX
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

typealias BackgroundTaskExpirationHandler = (BackgroundTaskProtocol) -> Void

/// BackgroundTaskProtocol is the protocol describing a background task regardless of the platform used.
protocol BackgroundTaskProtocol: AnyObject {
    /// Name of the background task for debug.
    var name: String { get }

    /// `true` if the background task is currently running.
    var isRunning: Bool { get }

    /// Flag indicating the background task is reusable. If reusable, `name` is the key to distinguish background tasks.
    var isReusable: Bool { get }

    /// Elapsed time after the task started. In milliseconds.
    var elapsedTime: TimeInterval { get }

    /// Expiration handler for the background task
    var expirationHandler: BackgroundTaskExpirationHandler? { get }

    /// Method to be called when a task reused one more time. Should only be valid for reusable tasks.
    func reuse()

    /// Stop the background task. Cannot be started anymore. For reusable tasks, should be called same number of times `reuse` called.
    func stop()
}
