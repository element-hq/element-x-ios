//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct MessageForwardingScreenViewModelTests {
    let forwardingItem = MessageForwardingItem(id: .event(uniqueID: .init("t1"), eventOrTransactionID: .eventID("t1")),
                                               roomID: "1",
                                               content: .init(noHandle: .init()))
    var viewModel: MessageForwardingScreenViewModelProtocol!
    var context: MessageForwardingScreenViewModelType.Context!
    
    init() {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { .joined(JoinedRoomProxyMock(.init(id: $0))) }
        
        viewModel = MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                     userIndicatorController: UserIndicatorControllerMock())
        context = viewModel.context
    }
    
    @Test
    func initialState() {
        #expect(context.viewState.rooms.first { $0.id == forwardingItem.roomID } == nil, "The source room ID shouldn't be shown")
    }
    
    @Test
    mutating func roomSelection() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        #expect(context.viewState.selectedRoomID == "2")
    }
    
    @Test
    mutating func searching() async throws {
        let deferred = deferFulfillment(context.$viewState) { state in
            state.rooms.count == 1
        }
        
        context.searchQuery = "Second"
            
        try await deferred.fulfill()
    }
    
    @Test
    mutating func forwarding() async throws {
        context.send(viewAction: .selectRoom(roomID: "2"))
        #expect(context.viewState.selectedRoomID == "2")
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .sent(let roomID):
                return roomID == "2"
            default:
                return false
            }
        }
        
        context.send(viewAction: .send)
        
        try await deferred.fulfill()
    }
}
