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
        XCTAssertEqual(state.enabledFilters, [])
        XCTAssertEqual(state.sortedAvailableFilters, RoomListFilter.allCases)
    }
    
    func testSetAndUnsetFilters() {
        state.set(.unreads, isEnabled: true)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [.unreads])
        XCTAssertEqual(state.sortedAvailableFilters, [.people, .rooms, .favourites])
        state.set(.unreads, isEnabled: false)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [])
        XCTAssertEqual(state.sortedAvailableFilters, RoomListFilter.allCases)
    }
    
    func testMutuallyExclusiveFilters() {
        state.set(.people, isEnabled: true)
        // This is not allowed and should do nothing
        state.set(.rooms, isEnabled: true)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [.people])
        XCTAssertEqual(state.sortedAvailableFilters, [.unreads, .favourites])
        state.set(.people, isEnabled: false)
        state.set(.rooms, isEnabled: true)
        // This is not allowed and should do nothing
        state.set(.people, isEnabled: true)
        state.set(.unreads, isEnabled: true)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [.rooms, .unreads])
        XCTAssertEqual(state.sortedAvailableFilters, [.favourites])
    }
    
    func testClearFilters() {
        state.set(.people, isEnabled: true)
        state.set(.unreads, isEnabled: true)
        state.set(.favourites, isEnabled: true)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [.people, .unreads, .favourites])
        XCTAssertEqual(state.sortedAvailableFilters, [])
        state.clearFilters()
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.enabledFilters, [])
        XCTAssertEqual(state.sortedAvailableFilters, RoomListFilter.allCases)
    }
}
