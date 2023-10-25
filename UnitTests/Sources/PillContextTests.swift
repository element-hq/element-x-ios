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
        let proxyMock = RoomProxyMock(with: .init(displayName: "Test"))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.members = subject.asCurrentValuePublisher()
        let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                       mediaProvider: MockMediaProvider(),
                                       mediaPlayerProvider: MediaPlayerProviderMock(),
                                       roomProxy: proxyMock,
                                       appSettings: ServiceLocator.shared.settings,
                                       analytics: ServiceLocator.shared.analytics,
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                       application: ApplicationMock())
        let context = PillContext(roomContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertNil(context.viewState.avatarURL)
        XCTAssertNil(context.viewState.name)
        XCTAssertEqual(context.viewState.contentID, id)
        XCTAssertEqual(context.viewState.displayText, id)
        
        let name = "Mr. Test"
        let avatarURL = URL(string: "https://test.jpg")
        subject.send([RoomMemberProxyMock(with: .init(userID: id, displayName: name, avatarURL: avatarURL, membership: .join))])
        await Task.yield()
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.avatarURL, avatarURL)
        XCTAssertEqual(context.viewState.name, name)
        XCTAssertEqual(context.viewState.contentID, id)
        XCTAssertEqual(context.viewState.displayText, name)
    }
    
    func testOwnUser() async throws {
        let id = "@test:matrix.org"
        let proxyMock = RoomProxyMock(with: .init(displayName: "Test", ownUserID: id))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.members = subject.asCurrentValuePublisher()
        let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                       mediaProvider: MockMediaProvider(),
                                       mediaPlayerProvider: MediaPlayerProviderMock(),
                                       roomProxy: proxyMock,
                                       appSettings: ServiceLocator.shared.settings,
                                       analytics: ServiceLocator.shared.analytics,
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                       application: ApplicationMock())
        let context = PillContext(roomContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertTrue(context.viewState.isOwnMention)
    }
    
    func testAllUsers() async throws {
        let avatarURL = URL(string: "https://matrix.jpg")
        let id = "test_room"
        let displayName = "Test"
        let proxyMock = RoomProxyMock(with: .init(id: id, displayName: displayName, avatarURL: avatarURL))
        let mockController = MockRoomTimelineController()
        mockController.roomProxy = proxyMock
        let mock = RoomScreenViewModel(timelineController: mockController,
                                       mediaProvider: MockMediaProvider(),
                                       mediaPlayerProvider: MediaPlayerProviderMock(),
                                       roomProxy: proxyMock,
                                       appSettings: ServiceLocator.shared.settings,
                                       analytics: ServiceLocator.shared.analytics,
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                       application: ApplicationMock())
        let context = PillContext(roomContext: mock.context, data: PillTextAttachmentData(type: .allUsers, font: .preferredFont(forTextStyle: .body)))
        
        XCTAssertTrue(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.avatarURL, avatarURL)
        XCTAssertEqual(context.viewState.name, displayName)
        XCTAssertEqual(context.viewState.contentID, id)
        XCTAssertEqual(context.viewState.displayText, "@room")
    }
}
