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

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
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
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        XCTAssertFalse(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssertTrue(context.viewState.details.isIgnored)
    }

    func testIgnoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        roomMemberProxyMock.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .failure(.ignoreUserFailed)
        }
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        context.send(viewAction: .showIgnoreAlert)
        await context.nextViewState()
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        await context.nextViewState()
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        XCTAssertFalse(context.viewState.details.isIgnored)
        await context.nextViewState()
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssertNotNil(context.errorAlert)
        XCTAssertFalse(context.viewState.details.isIgnored)
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
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))

        context.send(viewAction: .unignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        XCTAssertTrue(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssertFalse(context.viewState.details.isIgnored)
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
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))

        context.send(viewAction: .unignoreConfirmed)
        await Task.yield()
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        XCTAssertTrue(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssertTrue(context.viewState.details.isIgnored)
        XCTAssertNotNil(context.errorAlert)
    }

    func testInitialStateAccountOwner() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockMe
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.errorAlert)
    }

    func testInitialStateIgnoredUser() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        viewModel = RoomMemberDetailsViewModel(roomMemberProxy: roomMemberProxyMock, mediaProvider: MockMediaProvider())

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.errorAlert)
    }
}
