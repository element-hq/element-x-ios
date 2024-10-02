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
class PillContextTests: XCTestCase {
    func testUser() async throws {
        let id = "@test:matrix.org"
        let proxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: MockRoomTimelineController(),
                                     mediaProvider: MockMediaProvider(),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics)
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, id)
        
        let name = "Mr. Test"
        let avatarURL = URL(string: "https://test.jpg")
        subject.send([RoomMemberProxyMock(with: .init(userID: id, displayName: name, avatarURL: avatarURL, membership: .join))])
        await Task.yield()
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, "@\(name)")
    }
    
    func testOwnUser() async throws {
        let id = "@test:matrix.org"
        let proxyMock = JoinedRoomProxyMock(.init(name: "Test", ownUserID: id))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: MockRoomTimelineController(),
                                     mediaProvider: MockMediaProvider(),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics)
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertTrue(context.viewState.isOwnMention)
    }
    
    func testAllUsers() async throws {
        let avatarURL = URL(string: "https://matrix.jpg")
        let id = "test_room"
        let displayName = "Test"
        let proxyMock = JoinedRoomProxyMock(.init(id: id, name: displayName, avatarURL: avatarURL))
        let mockController = MockRoomTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     mediaProvider: MockMediaProvider(),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics)
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .allUsers, font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertTrue(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, PillConstants.atRoom)
    }
}
