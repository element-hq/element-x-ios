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

import Combine
import Foundation
import UIKit

enum AppDelegateCallback {
    case registeredNotifications(deviceToken: Data)
    case failedToRegisteredNotifications(error: Error)
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) static var shared: AppDelegate!
    let callbacks = PassthroughSubject<AppDelegateCallback, Never>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // worst singleton ever
        Self.shared = self
        NSTextAttachment.registerViewProviderClass(PillAttachmentViewProvider.self, forFileType: InfoPlistReader.main.pillsUTType)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        callbacks.send(.registeredNotifications(deviceToken: deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        callbacks.send(.failedToRegisteredNotifications(error: error))
    }
}
