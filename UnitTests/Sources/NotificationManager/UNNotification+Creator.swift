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
import UserNotifications
import XCTest

extension UNNotification {
    static func with(userInfo: [AnyHashable: Any], actionIdentifier: String = UNNotificationDefaultActionIdentifier) throws -> UNNotification {
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: "",
                                            content: content,
                                            trigger: nil)
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try XCTUnwrap(UNNotification(coder: archiver))
        notification.setValue(request, forKey: "request")
        return notification
    }
}
