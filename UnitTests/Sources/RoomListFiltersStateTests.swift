//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

final class RoomListFiltersStateTests: XCTestCase {
    var state: RoomListFiltersState!
    
    override func setUp() {
        state = RoomListFiltersState()
    }
    
    func testInitialState() {
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
    }
    
    func testSetAndUnsetFilters() {
        state.activateFilter(.unreads)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.unreads])
        XCTAssertEqual(state.availableFilters, [.people, .rooms, .favourites, .lowPriority])
        state.deactivateFilter(.unreads)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
    }
    
    func testMutuallyExclusiveFilters() {
        state.activateFilter(.people)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.people])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites, .lowPriority])
        
        state.deactivateFilter(.people)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
        
        state.activateFilter(.rooms)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.rooms])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites, .lowPriority])
        
        state.activateFilter(.unreads)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.rooms, .unreads])
        XCTAssertEqual(state.availableFilters, [.favourites, .lowPriority])
    }
    
    func testClearFilters() {
        state.activateFilter(.people)
        XCTAssertEqual(state.activeFilters, [.people])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])

        state.activateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.people, .unreads])
        XCTAssertEqual(state.availableFilters, [.favourites])

        state.activateFilter(.favourites)
        XCTAssertEqual(state.activeFilters, [.people, .unreads, .favourites])
        XCTAssertEqual(state.availableFilters, [])
        
        state.clearFilters()
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
    }
    
    func testOrder() {
        state.activateFilter(.favourites)
        XCTAssertEqual(state.activeFilters, [.favourites])
        XCTAssertEqual(state.availableFilters, [.unreads, .people, .rooms])

        state.deactivateFilter(.favourites)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
        
        state.activateFilter(.rooms)
        XCTAssertEqual(state.activeFilters, [.rooms])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites, .lowPriority])

        state.activateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.rooms, .unreads])
        XCTAssertEqual(state.availableFilters, [.favourites, .lowPriority])
        
        state.deactivateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.rooms])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites, .lowPriority])
    }
    
    func testLowPriorityFilterIncompatibility() {
        // Test that low priority cannot be combined with favourites
        state.activateFilter(.lowPriority)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.lowPriority])
        XCTAssertEqual(state.availableFilters, [.unreads, .people, .rooms])
        
        // Test that low priority cannot be combined with invites
        state.deactivateFilter(.lowPriority)
        state.activateFilter(.invites)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.invites])
        XCTAssertEqual(state.availableFilters, [])
        
        // Test that favourites cannot be combined with low priority
        state.deactivateFilter(.invites)
        state.activateFilter(.favourites)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.favourites])
        XCTAssertEqual(state.availableFilters, [.unreads, .people, .rooms])
    }
    
    func testLowPriorityFilterCompatibility() {
        // Test that low priority can be combined with other compatible filters
        state.activateFilter(.lowPriority)
        state.activateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.lowPriority, .unreads])
        XCTAssertEqual(state.availableFilters, [.people, .rooms])
        
        state.activateFilter(.people)
        XCTAssertEqual(state.activeFilters, [.lowPriority, .unreads, .people])
        XCTAssertEqual(state.availableFilters, [])
    }
}
