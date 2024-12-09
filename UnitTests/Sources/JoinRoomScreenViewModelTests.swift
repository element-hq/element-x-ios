//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class JoinRoomScreenViewModelTests: XCTestCase {
    var viewModel: JoinRoomScreenViewModelProtocol!
    
    var context: JoinRoomScreenViewModelType.Context {
        viewModel.context
    }
    
    override func tearDown() {
        viewModel = nil
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
        setupViewModel()
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInvite)
        
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInvite)
    }
    
    func testKnockedState() async throws {
        setupViewModel(knocked: true)
        
        try await deferFulfillment(viewModel.context.$viewState) { state in
            state.mode == .knocked
        }.fulfill()
    }
    
    func testCancelKnock() async throws {
        setupViewModel(knocked: true)
        
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
    
    private func setupViewModel(throwing: Bool = false, knocked: Bool = false) {
        let clientProxy = ClientProxyMock(.init())
        
        clientProxy.joinRoomViaReturnValue = throwing ? .failure(.sdkError(ClientProxyMockError.generic)) : .success(())
        
        clientProxy.roomPreviewForIdentifierViaReturnValue = .success(.init(roomID: "",
                                                                            name: nil,
                                                                            canonicalAlias: nil,
                                                                            topic: nil,
                                                                            avatarURL: nil,
                                                                            memberCount: 0,
                                                                            isHistoryWorldReadable: nil,
                                                                            isJoined: false,
                                                                            isInvited: false,
                                                                            isPublic: false,
                                                                            canKnock: false))
        
        if knocked {
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = KnockedRoomProxyMock(.init())
                // to test the cancel knock function
                roomProxy.cancelKnockUnderlyingReturnValue = .success(())
                return .knocked(roomProxy)
            }
        }
        
        ServiceLocator.shared.settings.knockingEnabled = true
        
        viewModel = JoinRoomScreenViewModel(roomID: "1",
                                            via: [],
                                            appSettings: ServiceLocator.shared.settings,
                                            clientProxy: clientProxy,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
