//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDKMocks
import Testing

@MainActor
struct RoomSelectionScreenViewModelTests {
    @Test
    func joinedRoomsOnlyWhenEmptyAndSearching() async throws {
        let viewModel = RoomSelectionScreenViewModel(userSession: UserSessionMock(.init()),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms + .mockInvites + .mockSpaceInvites))))
        let context = viewModel.context
        
        #expect(!context.viewState.rooms.contains { $0.id == "someAwesomeRoomId1" || $0.id == "someAwesomeRoomId2" })
        #expect(!context.viewState.rooms.contains { $0.id == "!space1:matrix.org" || $0.id == "!space2:matrix.org" })
        #expect(context.viewState.rooms.contains { $0.id == "7" })
        
        let deferred = deferFulfillment(context.$viewState) { $0.rooms.map(\.id) == ["3"] }
        context.searchQuery = "Second"
        try await deferred.fulfill()
        
        #expect(context.viewState.rooms.map(\.id) == ["3"])
    }
}
