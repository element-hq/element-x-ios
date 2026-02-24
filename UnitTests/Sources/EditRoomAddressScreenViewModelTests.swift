//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct EditRoomAddressScreenViewModelTests {
    var viewModel: EditRoomAddressScreenViewModelProtocol!
    
    var context: EditRoomAddressScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func canonicalAliasChosen() async throws {
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
    @Test
    mutating func alternativeAliasChosen() async throws {
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
    
    @Test
    mutating func buildAliasFromDisplayName() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.desiredAliasLocalPart == "room-name"
        }
        
        try await deferred.fulfill()
    }
    
    @Test
    mutating func correctMethodsCalledOnSaveWhenNoAliasExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        #expect(roomProxy.infoPublisher.value.canonicalAlias == nil)
        #expect(viewModel.context.viewState.bindings.desiredAliasLocalPart == "room-name")
        
        await waitForConfirmation("Wait for save", expectedCount: 2) { confirm in
            roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
                #expect(roomAlias == "#room-name:matrix.org")
                confirm()
                return .success(true)
            }
            
            roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
                #expect(altAliases == [])
                #expect(roomAlias == "#room-name:matrix.org")
                confirm()
                return .success(())
            }
            
            context.send(viewAction: .save)
        }
        
        #expect(roomProxy.publishRoomAliasInRoomDirectoryCalled)
        #expect(roomProxy.updateCanonicalAliasAltAliasesCalled)
        #expect(!roomProxy.removeRoomAliasFromRoomDirectoryCalled)
    }
    
    @Test
    mutating func correctMethodsCalledOnSaveWhenAliasOnSameHomeserverExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#old-room-name:matrix.org"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        context.desiredAliasLocalPart = "room-name"
        
        await waitForConfirmation("Wait for save", expectedCount: 3) { confirm in
            roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
                #expect(roomAlias == "#room-name:matrix.org")
                confirm()
                return .success(true)
            }
                
            roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
                #expect(altAliases == [])
                #expect(roomAlias == "#room-name:matrix.org")
                confirm()
                return .success(())
            }
                
            roomProxy.removeRoomAliasFromRoomDirectoryClosure = { roomAlias in
                #expect(roomAlias == "#old-room-name:matrix.org")
                confirm()
                return .success(true)
            }
                
            context.send(viewAction: .save)
        }
        
        #expect(roomProxy.publishRoomAliasInRoomDirectoryCalled)
        #expect(roomProxy.updateCanonicalAliasAltAliasesCalled)
        #expect(roomProxy.removeRoomAliasFromRoomDirectoryCalled)
    }
    
    @Test
    mutating func correctMethodsCalledOnSaveWhenAliasOnOtherHomeserverExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#old-room-name:element.io"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        context.desiredAliasLocalPart = "room-name"
        
        await waitForConfirmation("Wait for save", expectedCount: 2) { confirm in
            roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
                #expect(roomAlias == "#room-name:matrix.org")
                confirm()
                return .success(true)
            }
            
            roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
                #expect(altAliases == ["#room-name:matrix.org"])
                #expect(roomAlias == "#old-room-name:element.io")
                confirm()
                return .success(())
            }
            
            context.send(viewAction: .save)
        }
        
        #expect(roomProxy.publishRoomAliasInRoomDirectoryCalled)
        #expect(roomProxy.updateCanonicalAliasAltAliasesCalled)
        #expect(!roomProxy.removeRoomAliasFromRoomDirectoryCalled)
    }
}
