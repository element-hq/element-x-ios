//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class JoinRoomScreenViewModelTests: XCTestCase {
    private enum TestCase {
        case joined
        case knocked
        case invited
        case banned
    }
    
    var viewModel: JoinRoomScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    
    var context: JoinRoomScreenViewModelType.Context {
        viewModel.context
    }
    
    override func tearDown() {
        viewModel = nil
        clientProxy = nil
        AppSettings.resetAllSettings()
    }

    func testInteraction() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined }
        context.send(viewAction: .join)
        try await deferred.fulfill()
    }
    
    func testAcceptInviteInteraction() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined }
        context.send(viewAction: .acceptInvite)
        try await deferred.fulfill()
    }
    
    func testDeclineInviteInteraction() async throws {
        setupViewModel(state: .invited)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInvite)
        
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInvite)
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
    }
    
    func testKnockedState() async throws {
        setupViewModel(state: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { state in
            state.mode == .knocked
        }.fulfill()
    }
    
    func testCancelKnock() async throws {
        setupViewModel(state: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { state in
            state.mode == .knocked
        }.fulfill()
        
        context.send(viewAction: .cancelKnock)
        XCTAssertEqual(viewModel.context.alertInfo?.id, .cancelKnock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
    }
    
    func testDeclineAndBlockInviteInteraction() async throws {
        setupViewModel(state: .invited)
        let expectation = expectation(description: "Wait for the user to be ignored")
        clientProxy.ignoreUserClosure = { userID in
            defer { expectation.fulfill() }
            XCTAssertEqual(userID, "@test:matrix.org")
            return .success(())
        }
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInviteAndBlock(userID: "@test:matrix.org"))
        
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInviteAndBlock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
        
        await fulfillment(of: [expectation], timeout: 10)
    }
    
    func testForgetRoom() async throws {
        setupViewModel(state: .banned)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.send(viewAction: .forget)
        try await deferred.fulfill()
    }
    
    private func setupViewModel(throwing: Bool = false, state: TestCase = .joined) {
        ServiceLocator.shared.settings.knockingEnabled = true
        
        clientProxy = ClientProxyMock(.init())
        
        clientProxy.joinRoomViaReturnValue = throwing ? .failure(.sdkError(ClientProxyMockError.generic)) : .success(())
        
        switch state {
        case .knocked:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.knocked)
            
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = KnockedRoomProxyMock(.init())
                // to test the cancel knock function
                roomProxy.cancelKnockUnderlyingReturnValue = .success(())
                return .knocked(roomProxy)
            }
        case .joined:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.joinable)
        case .invited:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = InvitedRoomProxyMock(.init())
                roomProxy.rejectInvitationReturnValue = .success(())
                return .invited(roomProxy)
            }
        case .banned:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.banned)
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = BannedRoomProxyMock(.init())
                roomProxy.forgetRoomReturnValue = .success(())
                return .banned(roomProxy)
            }
        }
        
        viewModel = JoinRoomScreenViewModel(roomID: "1",
                                            via: [],
                                            appSettings: ServiceLocator.shared.settings,
                                            clientProxy: clientProxy,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
