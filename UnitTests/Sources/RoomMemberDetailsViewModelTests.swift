//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct RoomMemberDetailsViewModelTests {
    var viewModel: RoomMemberDetailsScreenViewModelProtocol!
    var roomProxyMock: JoinedRoomProxyMock!
    var roomMemberProxyMock: RoomMemberProxyMock!
    var context: RoomMemberDetailsScreenViewModelType.Context {
        viewModel.context
    }

    @Test
    mutating func initialState() async throws {
        setup(roomMemberProxyMock: .mockAlice)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(context.viewState.memberDetails == RoomMemberDetails(withProxy: roomMemberProxyMock))
        #expect(context.ignoreUserAlert == nil)
        #expect(context.alertInfo == nil)
    }

    @Test
    mutating func ignoreSuccess() async throws {
        setup(roomMemberProxyMock: .mockAlice)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        context.send(viewAction: .showIgnoreAlert)
        #expect(context.ignoreUserAlert == .init(action: .ignore))
        context.send(viewAction: .ignoreConfirmed)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.memberDetails?.isIgnored == true
        }
        try await deferred.fulfill()
        
        let memberDetails = try #require(context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        #expect(memberDetails.isIgnored)
        #expect(!context.viewState.isProcessingIgnoreRequest)
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomProxyMock.updateMembersCalled)
    }

    @Test
    mutating func ignoreFailure() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.ignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setup(roomMemberProxyMock: .mockAlice, clientProxy: clientProxy)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        context.send(viewAction: .showIgnoreAlert)
        #expect(context.ignoreUserAlert == .init(action: .ignore))
        context.send(viewAction: .ignoreConfirmed)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        try await deferred.fulfill()
        
        let memberDetails = try #require(context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        #expect(!memberDetails.isIgnored)
        #expect(context.alertInfo != nil)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(!roomProxyMock.updateMembersCalled)
    }

    @Test
    mutating func unignoreSuccess() async throws {
        setup(roomMemberProxyMock: .mockIgnored)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        context.send(viewAction: .showUnignoreAlert)
        #expect(context.ignoreUserAlert == .init(action: .unignore))
        context.send(viewAction: .unignoreConfirmed)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.memberDetails?.isIgnored == false
        }
        try await deferred.fulfill()
        
        let memberDetails = try #require(context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        #expect(!memberDetails.isIgnored)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomProxyMock.updateMembersCalled)
    }

    @Test
    mutating func unignoreFailure() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.unignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setup(roomMemberProxyMock: .mockIgnored, clientProxy: clientProxy)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        context.send(viewAction: .showUnignoreAlert)
        #expect(context.ignoreUserAlert == .init(action: .unignore))
        context.send(viewAction: .unignoreConfirmed)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        try await deferred.fulfill()
        
        let memberDetails = try #require(context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        #expect(memberDetails.isIgnored)
        #expect(context.alertInfo != nil)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(!roomProxyMock.updateMembersCalled)
    }

    @Test
    mutating func initialStateAccountOwner() async throws {
        setup(roomMemberProxyMock: .mockMe)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(context.viewState.memberDetails == RoomMemberDetails(withProxy: roomMemberProxyMock))
        #expect(context.ignoreUserAlert == nil)
        #expect(context.alertInfo == nil)
    }

    @Test
    mutating func initialStateIgnoredUser() async throws {
        setup(roomMemberProxyMock: .mockIgnored)
        
        let waitForMemberToLoad = deferFulfillment(context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(context.viewState.memberDetails == RoomMemberDetails(withProxy: roomMemberProxyMock))
        #expect(context.ignoreUserAlert == nil)
        #expect(context.alertInfo == nil)
    }

    // MARK: - Helpers

    private mutating func setup(roomMemberProxyMock: RoomMemberProxyMock, clientProxy: ClientProxyMock? = nil) {
        self.roomMemberProxyMock = roomMemberProxyMock
        roomProxyMock = JoinedRoomProxyMock(.init(name: ""))
        roomProxyMock.getMemberUserIDClosure = { _ in
            .success(roomMemberProxyMock)
        }
        // swiftlint:disable:next force_unwrapping
        let userSession = clientProxy != nil ? UserSessionMock(.init(clientProxy: clientProxy!)) : UserSessionMock(.init())
        viewModel = RoomMemberDetailsScreenViewModel(userID: roomMemberProxyMock.userID,
                                                     roomProxy: roomProxyMock,
                                                     userSession: userSession,
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     analytics: ServiceLocator.shared.analytics)
    }
}
