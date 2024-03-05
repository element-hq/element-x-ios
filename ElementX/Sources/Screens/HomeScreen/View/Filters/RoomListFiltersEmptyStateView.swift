//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        .previewLayout(.sizeThatFits)
    }
}
