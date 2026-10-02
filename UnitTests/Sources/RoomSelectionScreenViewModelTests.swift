//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct RoomSelectionScreenViewModelTests {
    @Test
    func upgradedRoomsAreNotListed() {
        let viewModel = RoomSelectionScreenViewModel(userSession: UserSessionMock(.init()),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))))
        
        #expect(!viewModel.context.viewState.rooms.isEmpty)
        #expect(!viewModel.context.viewState.rooms.contains { $0.id == "7" }, "Upgraded rooms shouldn't be shown")
    }
}
