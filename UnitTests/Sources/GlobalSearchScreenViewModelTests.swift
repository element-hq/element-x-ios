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
struct GlobalSearchScreenViewModelTests {
    var viewModel: GlobalSearchScreenViewModelProtocol!
    var context: GlobalSearchScreenViewModelType.Context!
    
    init() {
        viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                mediaProvider: MediaProviderMock(configuration: .init()))
        context = viewModel.context
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
    func roomSelection() async throws {
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .select(let roomID):
                return roomID == "2"
            default:
                return false
            }
        }
        
        context.send(viewAction: .select(roomID: "2"))
        
        try await deferred.fulfill()
    }
}
