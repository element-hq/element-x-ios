//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite(.serialized)
final class RoomListFiltersStateTests {
    var appSettings: AppSettings
    var state: RoomListFiltersState
    let allCasesWithoutLowPriority = RoomListFilter.allCases.filter { $0 != .lowPriority }
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        state = RoomListFiltersState(appSettings: appSettings)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func initialState() {
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == allCasesWithoutLowPriority)
    }
    
    @Test
    func setAndUnsetFilters() {
        state.activateFilter(.unreads)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.unreads])
        #expect(state.availableFilters == [.people, .rooms, .favourites])
        state.deactivateFilter(.unreads)
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == allCasesWithoutLowPriority)
    }
    
    @Test
    func mutuallyExclusiveFilters() {
        state.activateFilter(.people)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.people])
        #expect(state.availableFilters == [.unreads, .favourites])
        
        state.deactivateFilter(.people)
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == allCasesWithoutLowPriority)
        
        state.activateFilter(.rooms)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.rooms])
        #expect(state.availableFilters == [.unreads, .favourites])
        
        state.activateFilter(.unreads)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.rooms, .unreads])
        #expect(state.availableFilters == [.favourites])
    }
    
    @Test
    func clearFilters() {
        state.activateFilter(.people)
        #expect(state.activeFilters == [.people])
        #expect(state.availableFilters == [.unreads, .favourites])

        state.activateFilter(.unreads)
        #expect(state.activeFilters == [.people, .unreads])
        #expect(state.availableFilters == [.favourites])

        state.activateFilter(.favourites)
        #expect(state.activeFilters == [.people, .unreads, .favourites])
        #expect(state.availableFilters == [])
        
        state.clearFilters()
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == allCasesWithoutLowPriority)
    }
    
    @Test
    func order() {
        state.activateFilter(.favourites)
        #expect(state.activeFilters == [.favourites])
        #expect(state.availableFilters == [.unreads, .people, .rooms])

        state.deactivateFilter(.favourites)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == allCasesWithoutLowPriority)
        
        state.activateFilter(.rooms)
        #expect(state.activeFilters == [.rooms])
        #expect(state.availableFilters == [.unreads, .favourites])

        state.activateFilter(.unreads)
        #expect(state.activeFilters == [.rooms, .unreads])
        #expect(state.availableFilters == [.favourites])
        
        state.deactivateFilter(.unreads)
        #expect(state.activeFilters == [.rooms])
        #expect(state.availableFilters == [.unreads, .favourites])
    }
    
    // MARK: Low Priority feature flag
    
    /// Don't forget to add .lowPriority into the mix above when enabling the feature.
    @Test
    func withLowPriorityFeature() {
        enableLowPriorityFeature()
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == RoomListFilter.allCases)
        
        state.activateFilter(.lowPriority)
        #expect(state.activeFilters == [.lowPriority])
        #expect(state.availableFilters == [.unreads, .people, .rooms])
    }
    
    // MARK: - Helpers
    
    private func enableLowPriorityFeature() {
        appSettings.lowPriorityFilterEnabled = true
        state = RoomListFiltersState(appSettings: appSettings)
    }
}
