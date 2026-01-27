//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

final class RoomListFiltersStateTests: XCTestCase {
    var appSettings: AppSettings!
    
    var state: RoomListFiltersState!
    var allCasesWithoutLowPriority = RoomListFilter.allCases.filter { $0 != .lowPriority }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        state = RoomListFiltersState(appSettings: appSettings)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testInitialState() {
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, allCasesWithoutLowPriority)
    }
    
    func testSetAndUnsetFilters() {
        state.activateFilter(.unreads)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.unreads])
        XCTAssertEqual(state.availableFilters, [.people, .rooms, .favourites])
        state.deactivateFilter(.unreads)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, allCasesWithoutLowPriority)
    }
    
    func testMutuallyExclusiveFilters() {
        state.activateFilter(.people)
        XCTAssertTrue(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [.people])
        XCTAssertEqual(state.availableFilters, [.unreads, .favourites])
        
        state.deactivateFilter(.people)
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, allCasesWithoutLowPriority)
        
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
        XCTAssertEqual(state.availableFilters, allCasesWithoutLowPriority)
    }
    
    func testOrder() {
        state.activateFilter(.favourites)
        XCTAssertEqual(state.activeFilters, [.favourites])
        XCTAssertEqual(state.availableFilters, [.unreads, .people, .rooms])

        state.deactivateFilter(.favourites)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, allCasesWithoutLowPriority)
        
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
    
    // MARK: Low Priority feature flag
    
    /// Don't forget to add .lowPriority into the mix above when enabling the feature.
    func testWithLowPriorityFeature() {
        enableLowPriorityFeature()
        XCTAssertFalse(state.isFiltering)
        XCTAssertEqual(state.activeFilters, [])
        XCTAssertEqual(state.availableFilters, RoomListFilter.allCases)
        
        state.activateFilter(.lowPriority)
        XCTAssertEqual(state.activeFilters, [.lowPriority])
        XCTAssertEqual(state.availableFilters, [.unreads, .people, .rooms])
    }
    
    // MARK: - Helpers
    
    private func enableLowPriorityFeature() {
        appSettings.lowPriorityFilterEnabled = true
        state = RoomListFiltersState(appSettings: appSettings)
    }
}
