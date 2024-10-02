//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UserNotifications
import XCTest

extension UNNotification {
    static func with(userInfo: [AnyHashable: Any]) throws -> UNNotification {
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
