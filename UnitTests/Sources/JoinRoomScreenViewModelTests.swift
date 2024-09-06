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
    
    private func setupViewModel(throwing: Bool = false) {
        let clientProxy = ClientProxyMock(.init())
        
        clientProxy.joinRoomViaReturnValue = throwing ? .failure(.sdkError(ClientProxyMockError.generic)) : .success(())
        
        clientProxy.roomPreviewForIdentifierViaReturnValue = .success(.init(roomID: "",
                                                                            name: nil,
                                                                            canonicalAlias: nil,
                                                                            topic: nil,
                                                                            avatarURL: nil,
                                                                            memberCount: 0,
                                                                            isHistoryWorldReadable: false,
                                                                            isJoined: false,
                                                                            isInvited: false,
                                                                            isPublic: false,
                                                                            canKnock: false))
        
        viewModel = JoinRoomScreenViewModel(roomID: "1",
                                            via: [],
                                            clientProxy: clientProxy,
                                            mediaProvider: MockMediaProvider(),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
