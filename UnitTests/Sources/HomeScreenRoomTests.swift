//
// Copyright 2024 New Vector Ltd
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
import XCTest

@testable import ElementX

@MainActor
class HomeScreenRoomTests: XCTestCase {
    var roomSummaryDetails: RoomSummary!
    
    // swiftlint:disable:next function_parameter_count
    func setupRoomSummary(isMarkedUnread: Bool,
                          unreadMessagesCount: UInt,
                          unreadMentionsCount: UInt,
                          unreadNotificationsCount: UInt,
                          notificationMode: RoomNotificationModeProxy,
                          hasOngoingCall: Bool) {
        roomSummaryDetails = RoomSummary(id: "Test room",
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: true)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
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
        
        let room = HomeScreenRoom(details: roomSummaryDetails, invalidated: false, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertTrue(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
}
