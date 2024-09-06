//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct RoomListFiltersEmptyStateView: View {
    let state: RoomListFiltersState
    
    private var emptyStateTitle: String {
        if state.activeFilters.count == 1 {
            switch state.activeFilters[0] {
            case .unreads:
                return L10n.screenRoomlistFilterUnreadsEmptyStateTitle
            case .people:
                return L10n.screenRoomlistFilterPeopleEmptyStateTitle
            case .rooms:
                return L10n.screenRoomlistFilterRoomsEmptyStateTitle
            case .favourites:
                return L10n.screenRoomlistFilterFavouritesEmptyStateTitle
            case .invites:
                return L10n.screenRoomlistFilterInvitesEmptyStateTitle
            }
        }
        return L10n.screenRoomlistFilterMixedEmptyStateTitle
    }
    
    private var emptyStateSubtitle: String {
        if state.activeFilters.first == .favourites {
            return L10n.screenRoomlistFilterFavouritesEmptyStateSubtitle
        }
        return L10n.screenRoomlistFilterMixedEmptyStateSubtitle
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(emptyStateTitle)
                .multilineTextAlignment(.center)
                .font(.compound.headingSMSemibold)
                .foregroundColor(.compound.textPrimary)
            
            Text(emptyStateSubtitle)
                .multilineTextAlignment(.center)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(.horizontal, 60)
    }
}

struct RoomListFiltersEmptyStateView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 24) {
            ForEach(RoomListFilter.allCases) { filter in
                RoomListFiltersEmptyStateView(state: .init(activeFilters: [filter]))
            }
            RoomListFiltersEmptyStateView(state: .init(activeFilters: [.people, .favourites]))
        }
        .padding(.bottom)
        .previewLayout(.sizeThatFits)
    }
}
