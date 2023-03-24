//
// Copyright 2022 New Vector Ltd
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

import XCTest

@testable import ElementX

@MainActor
class RoomMemberDetailsViewModelTests: XCTestCase {
    var viewModel: RoomMemberDetailsViewModelProtocol!
    var roomMemberProxyMock: RoomMemberProxyMock!
    var context: RoomMemberDetailsViewModelType.Context { viewModel.context }

    func testInitialState() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        XCTAssertEqual(context.viewState.name, "Alice")
        XCTAssertFalse(context.viewState.isAccountOwner)
        XCTAssertFalse(context.viewState.isIgnored)
        XCTAssertEqual(context.viewState.userID, "@alice:matrix.org")
        XCTAssertEqual(context.viewState.permalink, URL(string: "https://matrix.to/#/@alice:matrix.org"))
        XCTAssertEqual(context.viewState.avatarURL, nil)
        XCTAssertNil(context.blockUserAlertItem)
        XCTAssertNil(context.errorAlert)
    }

    func testInitialStateAccountOwner() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockMe
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        XCTAssertEqual(context.viewState.name, "Me")
        XCTAssertTrue(context.viewState.isAccountOwner)
        XCTAssertFalse(context.viewState.isIgnored)
        XCTAssertEqual(context.viewState.userID, "@me:matrix.org")
        XCTAssertEqual(context.viewState.permalink, URL(string: "https://matrix.to/#/@me:matrix.org"))
        XCTAssertEqual(context.viewState.avatarURL, URL.picturesDirectory)
        XCTAssertNil(context.blockUserAlertItem)
        XCTAssertNil(context.errorAlert)
    }

    func testInitialStateIgnoredUser() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        XCTAssertEqual(context.viewState.name, "Ignored")
        XCTAssertFalse(context.viewState.isAccountOwner)
        XCTAssertTrue(context.viewState.isIgnored)
        XCTAssertEqual(context.viewState.userID, "@ignored:matrix.org")
        XCTAssertEqual(context.viewState.permalink, URL(string: "https://matrix.to/#/@ignored:matrix.org"))
        XCTAssertEqual(context.viewState.avatarURL, nil)
        XCTAssertNil(context.blockUserAlertItem)
        XCTAssertNil(context.errorAlert)
    }
}
