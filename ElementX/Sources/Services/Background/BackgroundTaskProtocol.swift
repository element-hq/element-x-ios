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
