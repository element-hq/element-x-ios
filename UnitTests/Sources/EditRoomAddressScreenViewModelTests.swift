//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class EditRoomAddressScreenViewModelTests: XCTestCase {
    var viewModel: EditRoomAddressScreenViewModelProtocol!
    
    var context: EditRoomAddressScreenViewModelType.Context {
        viewModel.context
    }
    
    func testCanonicalAliasChosen() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#room-name:matrix.org",
                                                  alternativeAliases: ["#beta:homeserver.io",
                                                                       "#alternative-room-name:matrix.org"]))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.desiredAliasLocalPart == "room-name"
        }
        
        try await deferred.fulfill()
    }
    
    /// Priority should be given to aliases from the current user's homeserver as they can edit those.
    func testAlternativeAliasChosen() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#alpha:homeserver.io",
                                                  alternativeAliases: ["#beta:homeserver.io",
                                                                       "#room-name:matrix.org",
                                                                       "#alternative-room-name:matrix.org"]))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.desiredAliasLocalPart == "room-name"
        }
        
        try await deferred.fulfill()
    }
    
    func testBuildAliasFromDisplayName() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.desiredAliasLocalPart == "room-name"
        }
        
        try await deferred.fulfill()
    }
    
    func testCorrectMethodsCalledOnSave() async throws {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name"))
        roomProxy.publishRoomAliasInRoomDirectoryReturnValue = .success(true)
        roomProxy.updateCanonicalAliasAltAliasesReturnValue = .success(())
        roomProxy.removeRoomAliasFromRoomDirectoryReturnValue = .success(true)
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        context.send(viewAction: .save)
    }
}
