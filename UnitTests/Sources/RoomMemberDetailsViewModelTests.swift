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
        roomProxyMock = RoomProxyMock(with: .init(name: ""))
        
        roomProxyMock.getMemberUserIDClosure = { _ in
            .success(self.roomMemberProxyMock)
        }
    }

    func testInitialState() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: ClientProxyMock(.init()),
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        XCTAssertEqual(context.viewState.memberDetails, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }

    func testIgnoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: ClientProxyMock(.init()),
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        context.send(viewAction: .showIgnoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))

        context.send(viewAction: .ignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.memberDetails?.isIgnored == true
        }
        
        try await deferred.fulfill()
        
        guard let memberDetails = context.viewState.memberDetails else {
            XCTFail("Member details should be loaded at this point")
            return
        }
        
        XCTAssertTrue(memberDetails.isIgnored)
        
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(roomProxyMock.updateMembersCalled)
    }

    func testIgnoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        let clientProxy = ClientProxyMock(.init())
        clientProxy.ignoreUserReturnValue = .failure(.failedIgnoringUser)
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: clientProxy,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        context.send(viewAction: .showIgnoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .ignore))
        
        context.send(viewAction: .ignoreConfirmed)

        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        guard let memberDetails = context.viewState.memberDetails else {
            XCTFail("Member details should be loaded at this point")
            return
        }
        
        XCTAssertFalse(memberDetails.isIgnored)
        
        XCTAssertNotNil(context.alertInfo)
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(roomProxyMock.updateMembersCalled)
    }

    func testUnignoreSuccess() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: ClientProxyMock(.init()),
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        context.send(viewAction: .showUnignoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))
        
        context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.memberDetails?.isIgnored == false
        }
        
        try await deferred.fulfill()
        
        guard let memberDetails = context.viewState.memberDetails else {
            XCTFail("Member details should be loaded at this point")
            return
        }
        
        XCTAssertFalse(memberDetails.isIgnored)
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(roomProxyMock.updateMembersCalled)
    }

    func testUnignoreFailure() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        let clientProxy = ClientProxyMock(.init())
        clientProxy.unignoreUserReturnValue = .failure(.failedUnignoringUser)
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: clientProxy,
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        context.send(viewAction: .showUnignoreAlert)
        XCTAssertEqual(context.ignoreUserAlert, .init(action: .unignore))
        
        context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        guard let memberDetails = context.viewState.memberDetails else {
            XCTFail("Member details should be loaded at this point")
            return
        }
        
        XCTAssertTrue(memberDetails.isIgnored)
        
        XCTAssertNotNil(context.alertInfo)
        
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(roomProxyMock.updateMembersCalled)
    }

    func testInitialStateAccountOwner() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockMe
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: ClientProxyMock(.init()),
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        XCTAssertEqual(context.viewState.memberDetails, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }

    func testInitialStateIgnoredUser() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockIgnored
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     clientProxy: ClientProxyMock(.init()),
                                                     mediaProvider: MockMediaProvider(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        XCTAssertEqual(context.viewState.memberDetails, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }
}
