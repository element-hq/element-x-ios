//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Dynamic
@testable import ElementX
import MatrixRustSDK
import XCTest

final class NotificationContentBuilderTests: XCTestCase {
    var notificationContentBuilder: NotificationContentBuilder!
    var mediaProvider: MediaProviderMock!
    var notificationContent: UNMutableNotificationContent!
    
    override func setUp() {
        notificationContent = .init()
        let stringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                          destination: .notification)
        mediaProvider = MediaProviderMock(configuration: .init())
        notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: stringBuilder,
                                                                notificationSoundName: UNNotificationSoundName("message.caf"),
                                                                userSession: NSEUserSessionMock(.init()))
    }
    
    func testDMMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        // Checking if nil without using asObject always fails
        XCTAssertNil(communicationContext.displayName.asObject)
        XCTAssertEqual(communicationContext.sender.displayName, "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }
    
    func testDMMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        // Checking if nil without using asObject always fails
        XCTAssertNil(communicationContext.displayName.asObject)
        XCTAssertEqual(communicationContext.sender.displayName, L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }
    
    func testDMMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: false,
                                                               threadRootEventID: "thread"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        XCTAssertEqual(communicationContext.displayName, L10n.commonThread)
        XCTAssertEqual(communicationContext.sender.displayName, "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.orgthread")
        XCTAssertEqual(notificationContent.attachments, [])
    }
    
    func testDMMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        XCTAssertEqual(communicationContext.displayName, L10n.commonThread)
        XCTAssertEqual(communicationContext.sender.displayName, L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.orgthread")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        
        XCTAssertEqual(communicationContext.displayName, "General")
        XCTAssertEqual(communicationContext.sender.displayName, "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }
    
    func testRoomMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        XCTAssertEqual(communicationContext.displayName, "General")
        XCTAssertEqual(communicationContext.sender.displayName, L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false,
                                                               threadRootEventID: "thread123"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        XCTAssertEqual(communicationContext.displayName, L10n.notificationThreadInRoom("General"))
        XCTAssertEqual(communicationContext.sender.displayName, "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.orgthread123")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread123"))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        XCTAssertEqual(communicationContext.displayName, L10n.notificationThreadInRoom("General"))
        XCTAssertEqual(communicationContext.sender.displayName, L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.orgthread123")
        XCTAssertEqual(notificationContent.attachments, [])
    }
}
