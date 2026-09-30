//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UserNotifications
import XCTest

extension UNTextInputNotificationResponse {
    static func with(userInfo: [AnyHashable: Any], date: Date? = nil, actionIdentifier: String = UNNotificationDefaultActionIdentifier) throws -> UNNotificationResponse {
        let notification = try UNNotification.with(userInfo: userInfo, date: date)
        let archiver = MockCoder(requiringSecureCoding: false)
        
        let response = try XCTUnwrap(UNTextInputNotificationResponse(coder: archiver))
        response.setValue(notification, forKey: "notification")
        response.setValue(actionIdentifier, forKey: "actionIdentifier")
        return response
    }
}
