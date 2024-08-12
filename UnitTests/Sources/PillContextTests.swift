//
// Copyright 2023 New Vector Ltd
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
class PillContextTests: XCTestCase {
    func testUser() async throws {
        let id = "@test:matrix.org"
        let proxyMock = RoomProxyMock(.init(name: "Test"))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = RoomScreenViewModel(roomProxy: proxyMock,
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
        let proxyMock = RoomProxyMock(.init(name: "Test", ownUserID: id))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = RoomScreenViewModel(roomProxy: proxyMock,
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
        let proxyMock = RoomProxyMock(.init(id: id, name: displayName, avatarURL: avatarURL))
        let mockController = MockRoomTimelineController()
        mockController.roomProxy = proxyMock
        let mock = RoomScreenViewModel(roomProxy: proxyMock,
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
