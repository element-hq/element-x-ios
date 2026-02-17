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
    @MainActor
    private struct TestSetup {
        var viewModel: RoomMemberDetailsScreenViewModelProtocol
        var roomProxyMock: JoinedRoomProxyMock
        var roomMemberProxyMock: RoomMemberProxyMock
        
        var context: RoomMemberDetailsScreenViewModelType.Context {
            viewModel.context
        }
        
        init(roomMemberProxyMock: RoomMemberProxyMock, clientProxy: ClientProxyMock? = nil) {
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

    @Test
    func initialState() async throws {
        let testSetup = TestSetup(roomMemberProxyMock: .mockAlice)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        #expect(testSetup.context.viewState.memberDetails == RoomMemberDetails(withProxy: testSetup.roomMemberProxyMock))
        #expect(testSetup.context.ignoreUserAlert == nil)
        #expect(testSetup.context.alertInfo == nil)
    }

    @Test
    func ignoreSuccess() async throws {
        let testSetup = TestSetup(roomMemberProxyMock: .mockAlice)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        testSetup.context.send(viewAction: .showIgnoreAlert)
        #expect(testSetup.context.ignoreUserAlert == .init(action: .ignore))

        testSetup.context.send(viewAction: .ignoreConfirmed)
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.memberDetails?.isIgnored == true
        }
        
        try await deferred.fulfill()
        
        let memberDetails = try #require(testSetup.context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        
        #expect(memberDetails.isIgnored)
        #expect(!testSetup.context.viewState.isProcessingIgnoreRequest)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(testSetup.roomProxyMock.updateMembersCalled)
    }

    @Test
    func ignoreFailure() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.ignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        let testSetup = TestSetup(roomMemberProxyMock: .mockAlice, clientProxy: clientProxy)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()
        
        testSetup.context.send(viewAction: .showIgnoreAlert)
        #expect(testSetup.context.ignoreUserAlert == .init(action: .ignore))
        
        testSetup.context.send(viewAction: .ignoreConfirmed)

        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        let memberDetails = try #require(testSetup.context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        
        #expect(!memberDetails.isIgnored)
        #expect(testSetup.context.alertInfo != nil)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(!testSetup.roomProxyMock.updateMembersCalled)
    }

    @Test
    func unignoreSuccess() async throws {
        let testSetup = TestSetup(roomMemberProxyMock: .mockIgnored)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        testSetup.context.send(viewAction: .showUnignoreAlert)
        #expect(testSetup.context.ignoreUserAlert == .init(action: .unignore))
        
        testSetup.context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.memberDetails?.isIgnored == false
        }
        
        try await deferred.fulfill()
        
        let memberDetails = try #require(testSetup.context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        
        #expect(!memberDetails.isIgnored)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(testSetup.roomProxyMock.updateMembersCalled)
    }

    @Test
    func unignoreFailure() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.unignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        let testSetup = TestSetup(roomMemberProxyMock: .mockIgnored, clientProxy: clientProxy)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        testSetup.context.send(viewAction: .showUnignoreAlert)
        #expect(testSetup.context.ignoreUserAlert == .init(action: .unignore))
        
        testSetup.context.send(viewAction: .unignoreConfirmed)
        
        let deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.bindings.alertInfo != nil
        }
        
        try await deferred.fulfill()
        
        let memberDetails = try #require(testSetup.context.viewState.memberDetails,
                                         "Member details should be loaded at this point")
        
        #expect(memberDetails.isIgnored)
        #expect(testSetup.context.alertInfo != nil)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(!testSetup.roomProxyMock.updateMembersCalled)
    }

    @Test
    func initialStateAccountOwner() async throws {
        let testSetup = TestSetup(roomMemberProxyMock: .mockMe)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        #expect(testSetup.context.viewState.memberDetails == RoomMemberDetails(withProxy: testSetup.roomMemberProxyMock))
        #expect(testSetup.context.ignoreUserAlert == nil)
        #expect(testSetup.context.alertInfo == nil)
    }

    @Test
    func initialStateIgnoredUser() async throws {
        let testSetup = TestSetup(roomMemberProxyMock: .mockIgnored)
        
        let waitForMemberToLoad = deferFulfillment(testSetup.context.$viewState) { $0.memberDetails != nil }
        try await waitForMemberToLoad.fulfill()

        #expect(testSetup.context.viewState.memberDetails == RoomMemberDetails(withProxy: testSetup.roomMemberProxyMock))
        #expect(testSetup.context.ignoreUserAlert == nil)
        #expect(testSetup.context.alertInfo == nil)
    }
}
