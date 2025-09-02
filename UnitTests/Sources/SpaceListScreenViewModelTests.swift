//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SpaceListScreenViewModelTests: XCTestCase {
    var joinedSpacesSubject: CurrentValueSubject<[SpaceRoomProxyProtocol], Never>!
    var spaceServiceProxy: SpaceServiceProxyMock!
    
    var viewModel: SpaceListScreenViewModelProtocol!
    
    var context: SpaceListScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() {
        setupViewModel()
        XCTAssertEqual(context.viewState.joinedSpaces.count, 3)
        XCTAssertEqual(context.viewState.joinedRoomsCount, 0)
    }
    
    func testJoinedSpacesSubscription() async throws {
        setupViewModel()
        
        var deferred = deferFulfillment(context.observe(\.viewState.joinedSpaces)) { $0.count == 0 }
        joinedSpacesSubject.send([])
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.joinedSpaces.count, 0)
        
        deferred = deferFulfillment(context.observe(\.viewState.joinedSpaces)) { $0.count == 1 }
        joinedSpacesSubject.send([
            SpaceRoomProxyMock(.init(isSpace: true))
        ])
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.joinedSpaces.count, 1)
    }
    
    func testSelectingSpace() async throws {
        setupViewModel()
        
        let selectedSpace = joinedSpacesSubject.value[0]
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectSpace(let spaceRoomListProxy) where spaceRoomListProxy.spaceRoomProxy.id == selectedSpace.id:
            break
        default:
            XCTFail("The action should select the space.")
        }
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        joinedSpacesSubject = .init([
            SpaceRoomProxyMock(.init(id: "space1", isSpace: true)),
            SpaceRoomProxyMock(.init(id: "space2", isSpace: true)),
            SpaceRoomProxyMock(.init(id: "space3", isSpace: true))
        ])
        spaceServiceProxy = SpaceServiceProxyMock(.init())
        spaceServiceProxy.joinedSpacesPublisher = joinedSpacesSubject.asCurrentValuePublisher()
        spaceServiceProxy.spaceRoomListForClosure = { .success(SpaceRoomListProxyMock(.init(spaceRoomProxy: $0))) }
        clientProxy.spaceService = spaceServiceProxy
        
        viewModel = SpaceListScreenViewModel(userSession: userSession,
                                             selectedSpacePublisher: .init(nil),
                                             userIndicatorController: UserIndicatorControllerMock())
    }
}
