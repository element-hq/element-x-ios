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

@MainActor
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
