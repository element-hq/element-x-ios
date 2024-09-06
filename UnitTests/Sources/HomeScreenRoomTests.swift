//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class HomeScreenRoomTests: XCTestCase {
    var roomSummary: RoomSummary!
    
    // swiftlint:disable:next function_parameter_count
    func setupRoomSummary(isMarkedUnread: Bool,
                          unreadMessagesCount: UInt,
                          unreadMentionsCount: UInt,
                          unreadNotificationsCount: UInt,
                          notificationMode: RoomNotificationModeProxy,
                          hasOngoingCall: Bool) {
        roomSummary = RoomSummary(roomListItem: .init(noPointer: .init()),
                                  id: "Test room",
                                  isInvite: false,
                                  inviter: nil,
                                  name: "Test room",
                                  isDirect: false,
                                  avatarURL: nil,
                                  heroes: [],
                                  lastMessage: nil,
                                  lastMessageFormattedTimestamp: nil,
                                  unreadMessagesCount: unreadMessagesCount,
                                  unreadMentionsCount: unreadMentionsCount,
                                  unreadNotificationsCount: unreadNotificationsCount,
                                  notificationMode: notificationMode,
                                  canonicalAlias: nil,
                                  hasOngoingCall: hasOngoingCall,
                                  isMarkedUnread: isMarkedUnread,
                                  isFavourite: false)
    }
    
    func testNoBadge() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testAllBadgesExceptMute() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testUnhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testHighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testHighlightedMentionAndDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testUnhighlightedCall() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMentionAndKeywordsUnhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMentionAndKeywordsUnhighlightedDotHidden() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: true)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    // MARK: - Mark unread
    
    func testMarkedUnreadDot() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMarkedUnreadDotAndMention() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testMarkedUnreadMuteDotAndCall() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .mute,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertTrue(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
}
