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
        XCTAssertEqual(state.availableFilters, [.people, .rooms, .favourites])
        state.deactivateFilter(.unreads)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
    }
    
    func testMutuallyExclusiveFilters() {
        state.activateFilter(.people)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.people])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])
        
        state.deactivateFilter(.people)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
        
        state.activateFilter(.rooms)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.rooms])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])
        
        state.activateFilter(.unreads)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.rooms, .unreads])
        XCTAssertEqual(state.availableFilters, [.favourites])
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
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])

        state.activateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.rooms, .unreads])
        XCTAssertEqual(state.availableFilters, [.favourites])
        
        state.deactivateFilter(.unreads)
        XCTAssertEqual(state.activeFilters, [.rooms])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])
    }
}
