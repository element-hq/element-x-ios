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
    var viewModel: RoomMemberDetailsScreenViewModelProtocol!
    var roomProxyMock: RoomProxyMock!
    var roomMemberProxyMock: RoomMemberProxyMock!
    var context: RoomMemberDetailsScreenViewModelType.Context { viewModel.context }

    override func setUp() async throws {
        roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
    }

    func testInitialState() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }

    func testIgnoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        roomMemberProxyMock.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .success(())
        }
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        context.send(viewAction: .showIgnoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.details.isIgnored
        }
        
        try await deferred.fulfill()
        
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssertTrue(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(roomProxyMock.updateMembersCalled)
    }

    func testIgnoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        roomMemberProxyMock.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.ignoreUserFailed)
        }
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        context.send(viewAction: .showIgnoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))
        
        context.send(viewAction: .ignoreConfirmed)

        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertNotNil(context.alertInfo)
        XCTAssertFalse(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(roomProxyMock.updateMembersCalled)
    }

    func testUnignoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        roomMemberProxyMock.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .success(())
        }
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        context.send(viewAction: .showUnignoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))
        
        context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.details.isIgnored == false
        }
        
        try await deferred.fulfill()
        
        XCTAssertFalse(context.viewState.details.isIgnored)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(roomProxyMock.updateMembersCalled)
    }

    func testUnignoreFailure() async throws {
        roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        roomMemberProxyMock.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.unignoreUserFailed)
        }
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        context.send(viewAction: .showUnignoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))
        
        context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.details.isIgnored)
        XCTAssertNotNil(context.alertInfo)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(roomProxyMock.updateMembersCalled)
    }

    func testInitialStateAccountOwner() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockMe
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }

    func testInitialStateIgnoredUser() async {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        viewModel = RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                     roomMemberProxy: roomMemberProxyMock,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)

        XCTAssertEqual(context.viewState.details, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }
}
