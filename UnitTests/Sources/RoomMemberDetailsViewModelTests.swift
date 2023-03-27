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
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.errorAlert)
    }

    func testIgnoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        roomMemberProxyMock.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .success(())
        }
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        context.send(viewAction: .showIgnoreAlert)
        await Task.yield()
        XCTAssertEqual(context.ignoreUserAlert, IgnoreUserAlertItem(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isIgnoreLoading)
        XCTAssertFalse(context.viewState.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isIgnoreLoading)
        XCTAssertTrue(context.viewState.isIgnored)
    }

    func testIgnoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        roomMemberProxyMock.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .failure(.ignoreUserFailed)
        }
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        context.send(viewAction: .showIgnoreAlert)
        await Task.yield()
        XCTAssertEqual(context.ignoreUserAlert, IgnoreUserAlertItem(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isIgnoreLoading)
        XCTAssertFalse(context.viewState.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isIgnoreLoading)
        XCTAssertNotNil(context.errorAlert)
        XCTAssertFalse(context.viewState.isIgnored)
    }

    func testUnignoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        roomMemberProxyMock.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .success(())
        }
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        context.send(viewAction: .showUnignoreAlert)
        await Task.yield()
        XCTAssertEqual(context.ignoreUserAlert, IgnoreUserAlertItem(action: .unignore))

        context.send(viewAction: .unignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isIgnoreLoading)
        XCTAssertTrue(context.viewState.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isIgnoreLoading)
        XCTAssertFalse(context.viewState.isIgnored)
    }

    func testUnignoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        roomMemberProxyMock.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .failure(.unignoreUserFailed)
        }
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        context.send(viewAction: .showUnignoreAlert)
        await Task.yield()
        XCTAssertEqual(context.ignoreUserAlert, IgnoreUserAlertItem(action: .unignore))

        context.send(viewAction: .unignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isIgnoreLoading)
        XCTAssertTrue(context.viewState.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isIgnoreLoading)
        XCTAssertTrue(context.viewState.isIgnored)
        XCTAssertNotNil(context.errorAlert)
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
        XCTAssertNil(context.ignoreUserAlert)
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
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.errorAlert)
    }
}
