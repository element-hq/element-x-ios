//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
            suggestions == [.user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init()))]
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
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ro", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil))]
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
            suggestions == [.allUsers(item: .allUsersMention(roomAvatar: nil)),
                            .user(item: .init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL, range: .init())),
                            .user(item: .init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL, range: .init()))]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "", range: .init()))
        try await deferred.fulfill()
    }
}

private extension MentionSuggestionItem {
    static func allUsersMention(roomAvatar: URL?) -> Self {
        MentionSuggestionItem(id: PillConstants.atRoom, displayName: PillConstants.everyone, avatarURL: roomAvatar, range: .init())
    }
}
