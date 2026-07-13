//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Dynamic
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing
import UserNotifications

nonisolated struct NotificationContentBuilderTests {
    var notificationContentBuilder: NotificationContentBuilder
    var mediaProvider: MediaProviderMock
    var notificationContent: UNMutableNotificationContent
    
    init() {
        notificationContent = .init()
        let stringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                          style: .plain)
        mediaProvider = MediaProviderMock(.init())
        notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: stringBuilder,
                                                                notificationSoundName: UNNotificationSoundName("message.caf"),
                                                                userSession: NSEUserSessionMock(.init()))
    }
    
    @Test
    mutating func dmMessageNotification() async {
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
        #expect(communicationContext.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName == "Alice")
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!test:matrix.org")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithMention() async {
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
        #expect(communicationContext.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName == L10n.notificationSenderMentionReply("Alice"))
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!test:matrix.org")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithThread() async {
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
        #expect(communicationContext.displayName == L10n.commonThread)
        #expect(communicationContext.sender.displayName == "Alice")
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!test:matrix.orgthread")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithThreadAndMention() async {
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
        #expect(communicationContext.displayName == L10n.commonThread)
        #expect(communicationContext.sender.displayName == L10n.notificationSenderMentionReply("Alice"))
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!test:matrix.orgthread")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotification() async {
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
        
        #expect(communicationContext.displayName == "General")
        #expect(communicationContext.sender.displayName == "Alice")
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound == nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!testroom:matrix.org")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotificationWithMention() async {
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
        #expect(communicationContext.displayName == "General")
        #expect(communicationContext.sender.displayName == L10n.notificationSenderMentionReply("Alice"))
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!testroom:matrix.org")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotificationWithThread() async {
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
        #expect(communicationContext.displayName == L10n.notificationThreadInRoom("General"))
        #expect(communicationContext.sender.displayName == "Alice")
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound == nil)
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!testroom:matrix.orgthread123")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func knockNotification() async {
        let event = TimelineEventSDKMock()
        event.eventIdReturnValue = UUID().uuidString
        event.contentReturnValue = .state(content: .roomMemberContent(userId: "@charlie:matrix.org", membershipState: .knock))
        
        let notificationItem = NotificationItemProxyMock(.init(event: .timeline(event: event),
                                                               roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Charlie",
                                                               roomDisplayName: "Secret Club",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName == "Charlie")
        #expect(notificationContent.body == UntranslatedL10n.notificationKnockRequestBody)
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.sound != nil)
    }
    
    @Test
    mutating func otherMembershipStateEventNotification() async {
        let event = TimelineEventSDKMock()
        event.eventIdReturnValue = UUID().uuidString
        event.contentReturnValue = .state(content: .roomMemberContent(userId: "@charlie:matrix.org", membershipState: .join))
        
        let notificationItem = NotificationItemProxyMock(.init(event: .timeline(event: event),
                                                               roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Charlie",
                                                               roomDisplayName: "Secret Club",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        // Non-knock membership state events fall back to the generic notification.
        #expect(notificationContent.body == L10n.notification)
    }
    
    @Test
    mutating func roomMessageNotificationWithThreadAndMention() async {
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
        #expect(communicationContext.displayName == L10n.notificationThreadInRoom("General"))
        #expect(communicationContext.sender.displayName == L10n.notificationSenderMentionReply("Alice"))
        #expect(notificationContent.body == "Hello world!")
        #expect(notificationContent.categoryIdentifier == NotificationConstants.Category.message)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        #expect(notificationContent.threadIdentifier == "bob:matrix.org!testroom:matrix.orgthread123")
        #expect(notificationContent.attachments == [])
    }
}
