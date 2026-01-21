//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum RoomSummaryProviderState {
    case notLoaded
    case loaded(totalNumberOfRooms: UInt)
    
    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    var totalNumberOfRooms: UInt? {
        switch self {
        case .loaded(let totalNumberOfRooms):
            return totalNumberOfRooms
        default:
            return nil
        }
    }
}

enum RoomSummaryProviderFilter: Equatable {
    /// Filters out everything
    case excludeAll
    /// Includes only the items that satisfy the predicate logic
    case search(query: String)
    /// Includes only what satisfies the filters used
    case all(filters: Set<RoomListFilter>)
    /// Include only rooms from the given that satisfy the given filters
    case rooms(roomsIDs: Set<String>, filters: Set<RoomListFilter>)
}

// sourcery: AutoMockable
protocol StaticRoomSummaryProviderProtocol {
    /// Publishes the current state the summary provider is finding itself in
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> { get }
    
    /// Publishes the currently available room summaries
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> { get }
    
    func setRoomList(_ roomList: RoomList)
}

// sourcery: AutoMockable
protocol RoomSummaryProviderProtocol: StaticRoomSummaryProviderProtocol {
    func updateVisibleRange(_ range: Range<Int>)
    
    func setFilter(_ filter: RoomSummaryProviderFilter)
}
