//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

final class NotificationContentBuilderTests: XCTestCase {
    var notificationContentBuilder: NotificationContentBuilder!
    var mediaProvider: MediaProviderMock!
    
    override func setUp() {
        let stringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                          destination: .notification)
        mediaProvider = MediaProviderMock(configuration: .init())
        notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: stringBuilder,
                                                                userSession: NSEUserSessionMock(.init()))
    }
    
    func testDMMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true))
        var notificationContent = UNMutableNotificationContent()
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        XCTAssertEqual(notificationContent.title, "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
    }
}
