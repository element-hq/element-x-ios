//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
final class CompletionSuggestionServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        cancellables.removeAll()
    }
    
    func testUserSuggestions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock)
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(), rawSuggestionText: "ali"))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ali", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "me", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "room", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "everyon", range: .init()))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionsIncludingAllUsers() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members, canUserTriggerRoomNotification: true))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock)
                
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil, rawSuggestionText: "ro"))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ro", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil, rawSuggestionText: "every"))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "every", range: .init()))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionsWithEmptyText() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let bob: RoomMemberProxyMock = .mockBob
        let members: [RoomMemberProxyMock] = [alice, bob, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members, canUserTriggerRoomNotification: true))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock)
                
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil, rawSuggestionText: "")),
                            .user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(), rawSuggestionText: "")),
                            .user(item: .init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL, range: .init(), rawSuggestionText: ""))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "", range: .init()))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionInDifferentMessagePositions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock)
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(location: 0, length: 3), rawSuggestionText: "al"))]
        }
        service.processTextMessage("@al hello", selectedRange: .init(location: 0, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(location: 5, length: 3), rawSuggestionText: "al"))]
        }
        service.processTextMessage("test @al", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(location: 5, length: 3), rawSuggestionText: "al"))]
        }
        service.processTextMessage("test @al test", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionWithMultipleMentionSymbol() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let bob: RoomMemberProxyMock = .mockBob
        let members: [RoomMemberProxyMock] = [alice, bob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock)
        
        var deffered = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init(location: 0, length: 3), rawSuggestionText: "al"))]
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 0, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == [.user(item: .init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL, range: .init(location: 9, length: 3), rawSuggestionText: "bo"))]
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 9, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == []
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 4, length: 1))
        try await deffered.fulfill()
    }
}

private extension MentionSuggestionItem {
    static func allUsersMention(roomAvatar: URL?, rawSuggestionText: String) -> Self {
        MentionSuggestionItem(id: PillConstants.atRoom, displayName: PillConstants.everyone, avatarURL: roomAvatar, range: .init(), rawSuggestionText: rawSuggestionText)
    }
}
