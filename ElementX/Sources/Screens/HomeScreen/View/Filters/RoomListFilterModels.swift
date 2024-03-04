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

import Combine
import Foundation

import MatrixRustSDK
import OrderedCollections

enum RoomListFilter: Int, CaseIterable, Identifiable {
    var id: Int {
        rawValue
    }
    
    case unreads
    case people
    case rooms
    case favourites
    
    var localizedName: String {
        switch self {
        case .people:
            return L10n.screenRoomlistFilterPeople
        case .rooms:
            return L10n.screenRoomlistFilterRooms
        case .unreads:
            return L10n.screenRoomlistFilterUnreads
        case .favourites:
            return L10n.screenRoomlistFilterFavourites
        }
    }
    
    var incompatibleFilter: RoomListFilter? {
        switch self {
        case .people:
            return .rooms
        case .rooms:
            return .people
        case .unreads:
            return nil
        case .favourites:
            // When we will have Low Priority we may need to return it here
            return nil
        }
    }
    
    var rustFilter: RoomListEntriesDynamicFilterKind {
        switch self {
        case .people:
            return .category(expect: .people)
        case .rooms:
            return .category(expect: .group)
        case .unreads:
            return .unread
        case .favourites:
            return .favourite
        }
    }
}

struct RoomListFiltersState {
    private(set) var activeFilters: OrderedSet<RoomListFilter>
    private var inactiveFilters: OrderedSet<RoomListFilter>
    
    init(activeFilters: OrderedSet<RoomListFilter> = []) {
        self.activeFilters = .init(activeFilters)
        inactiveFilters = OrderedSet(RoomListFilter.allCases).subtracting(activeFilters)
    }
    
    var availableFilters: [RoomListFilter] {
        var availableFilters = inactiveFilters
        for filter in activeFilters {
            if let incompatibleFilter = filter.incompatibleFilter {
                availableFilters.remove(incompatibleFilter)
            }
        }
        return availableFilters.elements
    }
    
    var isFiltering: Bool {
        !activeFilters.isEmpty
    }
    
    mutating func activateFilter(_ filter: RoomListFilter) {
        if let incompatibleFilter = filter.incompatibleFilter,
           activeFilters.contains(incompatibleFilter) {
            fatalError("[RoomListFiltersState] adding mutually exclusive filters is not allowed")
        }
        activeFilters.append(filter)
        inactiveFilters.remove(filter)
    }
    
    mutating func deactivateFilter(_ filter: RoomListFilter) {
        activeFilters.remove(filter)
        // We always want the most recent filter to be disabled to be on top of the others
        inactiveFilters.insert(filter, at: 0)
    }
    
    mutating func clearFilters() {
        // We iterate in reverse because filters should get disabled starting from the first that has been used to the first that has been used.
        for filter in activeFilters.reversed() {
            deactivateFilter(filter)
        }
    }
    
    func isFilterActive(_ filter: RoomListFilter) -> Bool {
        activeFilters.contains(filter)
    }
}
