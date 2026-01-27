//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class RoomMemberDetailsViewModelTests: XCTestCase {
    var viewModel: RoomMemberDetailsScreenViewModelProtocol!
    var roomProxyMock: JoinedRoomProxyMock!
    var roomMemberProxyMock: RoomMemberProxyMock!
    var context: RoomMemberDetailsScreenViewModelType.Context {
        viewModel.context
    }

    override func setUp() async throws {
        roomProxyMock = JoinedRoomProxyMock(.init(name: ""))
        
        roomProxyMock.getMemberUserIDClosure = { _ in
            .success(self.roomMemberProxyMock)
        }
    }

    func testInitialState() async throws {
        roomMemberProxyMock = RoomMemberProxyMock.mockAlice
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     userSession: UserSessionMock(.init()),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
                                                     userSession: UserSessionMock(.init()),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
        clientProxy.ignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
                                                     userSession: UserSessionMock(.init()),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
        clientProxy.unignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
                                                     userSession: UserSessionMock(.init()),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
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
                                                     userSession: UserSessionMock(.init()),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        XCTAssertEqual(context.viewState.memberDetails, RoomMemberDetails(withProxy: roomMemberProxyMock))
        XCTAssertNil(context.ignoreUserAlert)
        XCTAssertNil(context.alertInfo)
    }
}
