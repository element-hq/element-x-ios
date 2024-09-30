//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    case invites
    
    static var availableFilters: [RoomListFilter] {
        RoomListFilter.allCases
    }
    
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
        case .invites:
            return L10n.screenRoomlistFilterInvites
        }
    }
    
    var incompatibleFilters: [RoomListFilter] {
        switch self {
        case .people:
            return [.rooms, .invites]
        case .rooms:
            return [.people, .invites]
        case .unreads:
            return [.invites]
        case .favourites:
            // When we will have Low Priority we may need to return it here
            return [.invites]
        case .invites:
            return [.rooms, .people, .unreads, .favourites]
        }
    }
    
    var rustFilter: RoomListEntriesDynamicFilterKind {
        switch self {
        case .people:
            return .all(filters: [.category(expect: .people), .joined])
        case .rooms:
            return .all(filters: [.category(expect: .group), .joined])
        case .unreads:
            return .all(filters: [.unread, .joined])
        case .favourites:
            return .all(filters: [.favourite, .joined])
        case .invites:
            return .invite
        }
    }
}

struct RoomListFiltersState {
    private(set) var activeFilters: OrderedSet<RoomListFilter>
    
    init(activeFilters: OrderedSet<RoomListFilter> = []) {
        self.activeFilters = .init(activeFilters)
    }
    
    var availableFilters: [RoomListFilter] {
        var availableFilters = OrderedSet(RoomListFilter.availableFilters)
        
        for filter in activeFilters {
            availableFilters.remove(filter)
            filter.incompatibleFilters.forEach { availableFilters.remove($0) }
        }
        
        return availableFilters.elements
    }
    
    var isFiltering: Bool {
        !activeFilters.isEmpty
    }
    
    mutating func activateFilter(_ filter: RoomListFilter) {
        filter.incompatibleFilters.forEach { incompatibleFilter in
            if activeFilters.contains(incompatibleFilter) {
                fatalError("[RoomListFiltersState] adding mutually exclusive filters is not allowed")
            }
        }
        
        // We always want the most recently enabled filter to be at the bottom of the others.
        activeFilters.append(filter)
    }
    
    mutating func deactivateFilter(_ filter: RoomListFilter) {
        activeFilters.remove(filter)
    }
    
    mutating func clearFilters() {
        activeFilters.removeAll()
    }
    
    func isFilterActive(_ filter: RoomListFilter) -> Bool {
        activeFilters.contains(filter)
    }
}
