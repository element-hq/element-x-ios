//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

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
    
    func testCorrectMethodsCalledOnSaveWhenNoAliasExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        XCTAssertNil(roomProxy.infoPublisher.value.canonicalAlias)
        XCTAssertEqual(viewModel.context.viewState.bindings.desiredAliasLocalPart, "room-name")

        let publishingExpectation = expectation(description: "Wait for publishing")
        roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
            defer { publishingExpectation.fulfill() }
            XCTAssertEqual(roomAlias, "#room-name:matrix.org")
            return .success(true)
        }
        
        let updateAliasExpectation = expectation(description: "Wait for alias update")
        roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
            defer { updateAliasExpectation.fulfill() }
            XCTAssertEqual(altAliases, [])
            XCTAssertEqual(roomAlias, "#room-name:matrix.org")
            return .success(())
        }
        
        context.send(viewAction: .save)
        await fulfillment(of: [publishingExpectation, updateAliasExpectation], timeout: 1.0)
        XCTAssertFalse(roomProxy.removeRoomAliasFromRoomDirectoryCalled)
    }
    
    func testCorrectMethodsCalledOnSaveWhenAliasOnSameHomeserverExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#old-room-name:matrix.org"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        context.desiredAliasLocalPart = "room-name"

        let publishingExpectation = expectation(description: "Wait for publishing")
        roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
            defer { publishingExpectation.fulfill() }
            XCTAssertEqual(roomAlias, "#room-name:matrix.org")
            return .success(true)
        }
        
        let updateAliasExpectation = expectation(description: "Wait for alias update")
        roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
            defer { updateAliasExpectation.fulfill() }
            XCTAssertEqual(altAliases, [])
            XCTAssertEqual(roomAlias, "#room-name:matrix.org")
            return .success(())
        }
        
        let removeAliasExpectation = expectation(description: "Wait for alias removal")
        roomProxy.removeRoomAliasFromRoomDirectoryClosure = { roomAlias in
            defer { removeAliasExpectation.fulfill() }
            XCTAssertEqual(roomAlias, "#old-room-name:matrix.org")
            return .success(true)
        }
        
        context.send(viewAction: .save)
        await fulfillment(of: [publishingExpectation, updateAliasExpectation, removeAliasExpectation], timeout: 1.0)
    }
    
    func testCorrectMethodsCalledOnSaveWhenAliasOnOtherHomeserverExists() async {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(true)
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#old-room-name:element.io"))
        
        viewModel = EditRoomAddressScreenViewModel(roomProxy: roomProxy,
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        context.desiredAliasLocalPart = "room-name"

        let publishingExpectation = expectation(description: "Wait for publishing")
        roomProxy.publishRoomAliasInRoomDirectoryClosure = { roomAlias in
            defer { publishingExpectation.fulfill() }
            XCTAssertEqual(roomAlias, "#room-name:matrix.org")
            return .success(true)
        }
        
        let updateAliasExpectation = expectation(description: "Wait for alias update")
        roomProxy.updateCanonicalAliasAltAliasesClosure = { roomAlias, altAliases in
            defer { updateAliasExpectation.fulfill() }
            XCTAssertEqual(altAliases, ["#room-name:matrix.org"])
            XCTAssertEqual(roomAlias, "#old-room-name:element.io")
            return .success(())
        }
        
        context.send(viewAction: .save)
        await fulfillment(of: [publishingExpectation, updateAliasExpectation], timeout: 1.0)
        XCTAssertFalse(roomProxy.removeRoomAliasFromRoomDirectoryCalled)
    }
}
