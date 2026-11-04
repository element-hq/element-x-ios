//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

struct JoinedRoomProxyTests {
    private let room = RoomSDKMock()
    private let membersIterator = RoomMembersIteratorSDKMock()
    
    @Test("A member's rename is signalled and reaches the typing indicator and member lookups")
    func memberRename() async throws {
        let subscribedRoom = try await makeSubscribedRoom(members: [.mock(userID: "@alice:matrix.org", displayName: "Alice")])
        let roomProxy = subscribedRoom.proxy
        #expect(room.subscribeToStateEventsEventTypeListenerReceivedArguments?.eventType == .roomMember)
        
        let typingBeforeRename = deferFulfillment(roomProxy.typingMembersPublisher) { $0 == ["Alice"] }
        subscribedRoom.typingListener.call(typingUserIds: ["@alice:matrix.org"])
        try await typingBeforeRename.fulfill()
        
        setMembers([.mock(userID: "@alice:matrix.org", displayName: "Alicia")])
        let renamedMembers = deferFulfillment(roomProxy.membersPublisher.map { $0.map(\.displayName) }) { $0 == ["Alicia"] }
        let membershipChange = deferFulfillment(roomProxy.membershipChangePublisher) { _ in true }
        subscribedRoom.memberChangesListener.onUpdate(events: [])
        try await renamedMembers.fulfill()
        try await membershipChange.fulfill()
        
        let typingAfterRename = deferFulfillment(roomProxy.typingMembersPublisher) { $0 == ["Alicia"] }
        subscribedRoom.typingListener.call(typingUserIds: ["@alice:matrix.org"])
        try await typingAfterRename.fulfill()
        
        let member = try await roomProxy.getMember(userID: "@alice:matrix.org").get()
        #expect(member.displayName == "Alicia")
    }
    
    @Test("A member update that changes nothing isn't published or signalled again")
    func unchangedMembersNotRepublished() async throws {
        // Only the store read publishes, so nothing else can emit during the check below.
        room.membersFetchingGlobalProfilesThrowableError = TestError.offline
        let subscribedRoom = try await makeSubscribedRoom(members: [.mock(userID: "@alice:matrix.org", displayName: "Alice")])
        let storeReadsBefore = room.membersNoSyncCallsCount
        
        let republished = deferFailure(subscribedRoom.proxy.membersPublisher.dropFirst().map { $0.map(\.userID) }, timeout: .seconds(1)) { _ in true }
        let signalled = deferFailure(subscribedRoom.proxy.membershipChangePublisher, timeout: .seconds(1)) { _ in true }
        subscribedRoom.memberChangesListener.onUpdate(events: [])
        try await republished.fulfill()
        try await signalled.fulfill()
        
        #expect(room.membersNoSyncCallsCount == storeReadsBefore + 1)
    }
    
    @Test("A typing user without a display name, or who isn't a member, is shown by their user ID")
    func typingUserIDFallback() async throws {
        let subscribedRoom = try await makeSubscribedRoom(members: [.mock(userID: "@bob:matrix.org", displayName: nil)])
        
        let typingMembers = deferFulfillment(subscribedRoom.proxy.typingMembersPublisher) { !$0.isEmpty }
        subscribedRoom.typingListener.call(typingUserIds: ["@bob:matrix.org", "@carol:matrix.org"])
        
        #expect(try await typingMembers.fulfill() == ["@bob:matrix.org", "@carol:matrix.org"])
    }
    
    // MARK: - Helpers
    
    private enum TestError: Error {
        case offline
    }
    
    private struct SubscribedRoom {
        let proxy: JoinedRoomProxy
        let memberChangesListener: RoomStateEventsListener
        let typingListener: TypingNotificationsListener
    }
    
    private func makeSubscribedRoom(members: [RoomMember]) async throws -> SubscribedRoom {
        setMembers(members)
        room.idReturnValue = "!room:matrix.org"
        room.roomInfoReturnValue = .mock(id: "!room:matrix.org")
        room.timelineWithConfigurationConfigurationReturnValue = makeTimeline()
        room.membersNoSyncReturnValue = membersIterator
        room.membersFetchingGlobalProfilesReturnValue = membersIterator
        room.encryptionStateReturnValue = .notEncrypted
        room.subscribeToRoomInfoUpdatesListenerReturnValue = TaskHandleSDKMock()
        room.subscribeToKnockRequestsListenerReturnValue = TaskHandleSDKMock()
        
        let roomProxy = try await JoinedRoomProxy(roomListService: RoomListServiceSDKMock(),
                                                  room: room,
                                                  userSettings: UserSettings.mock(),
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  eventStringBuilder: makeEventStringBuilder())
        
        let loadedMembers = deferFulfillment(roomProxy.membersPublisher.map { $0.map(\.userID) }) { $0 == members.map(\.userId) }
        try await loadedMembers.fulfill()
        
        await waitForConfirmation("Subscribed to member changes and typing notifications", expectedCount: 2, timeout: .seconds(10)) { confirmation in
            room.subscribeToStateEventsEventTypeListenerClosure = { _, _ in
                confirmation()
                return TaskHandleSDKMock()
            }
            room.subscribeToTypingNotificationsListenerClosure = { _ in
                confirmation()
                return TaskHandleSDKMock()
            }
            Task { await roomProxy.subscribeForUpdates() }
        }
        
        return try SubscribedRoom(proxy: roomProxy,
                                  memberChangesListener: #require(room.subscribeToStateEventsEventTypeListenerReceivedArguments?.listener),
                                  typingListener: #require(room.subscribeToTypingNotificationsListenerReceivedListener))
    }
    
    private func setMembers(_ members: [RoomMember]) {
        membersIterator.lenReturnValue = UInt32(members.count)
        membersIterator.nextChunkChunkSizeReturnValue = members
    }
    
    private func makeTimeline() -> TimelineSDKMock {
        let timeline = TimelineSDKMock()
        timeline.subscribeToBackPaginationStatusListenerReturnValue = TaskHandleSDKMock()
        timeline.addListenerListenerReturnValue = TaskHandleSDKMock()
        return timeline
    }
    
    private func makeEventStringBuilder() -> RoomEventStringBuilder {
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        return RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@me:matrix.org"),
                                      messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: attributedStringBuilder,
                                                                                               style: .senderPrefixed),
                                      shouldPrefixSenderName: true)
    }
}

private extension RoomMember {
    static func mock(userID: String, displayName: String?) -> RoomMember {
        RoomMember(userId: userID,
                   displayName: displayName,
                   avatarUrl: nil,
                   status: nil,
                   call: nil,
                   membership: .join,
                   isNameAmbiguous: false,
                   powerLevel: .value(value: 0),
                   isIgnored: false,
                   suggestedRoleForPowerLevel: .user,
                   membershipChangeReason: nil,
                   isServiceMember: false)
    }
}

private extension RoomInfo {
    static func mock(id: String) -> RoomInfo {
        RoomInfo(id: id,
                 encryptionState: .notEncrypted,
                 creators: nil,
                 displayName: "Room",
                 rawName: nil,
                 topic: nil,
                 avatarUrl: nil,
                 isDirect: false,
                 isDm: false,
                 isPublic: nil,
                 isSpace: false,
                 successorRoom: nil,
                 isFavourite: false,
                 isLowPriority: false,
                 canonicalAlias: nil,
                 alternativeAliases: [],
                 membership: .joined,
                 inviter: nil,
                 heroes: [],
                 activeMembersCount: 0,
                 invitedMembersCount: 0,
                 joinedMembersCount: 0,
                 activeServiceMembersCount: 0,
                 serviceMembers: [],
                 highlightCount: 0,
                 notificationCount: 0,
                 cachedUserDefinedNotificationMode: nil,
                 hasRoomCall: false,
                 activeRoomCallParticipants: [],
                 activeRoomCallConsensusIntent: .none,
                 isMarkedUnread: false,
                 numUnreadMessages: 0,
                 numUnreadNotifications: 0,
                 numUnreadMentions: 0,
                 fullyReadEventId: nil,
                 pinnedEventIds: [],
                 joinRule: nil,
                 historyVisibility: .shared,
                 powerLevels: nil,
                 roomVersion: nil,
                 privilegedCreatorsRole: false)
    }
}
