//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
final class RoomListFiltersStateTests {
    var appSettings: AppSettings
    var state: RoomListFiltersState
    /// The filters that aren't hidden behind a feature flag.
    let defaultFilters = RoomListFilter.allCases.filter { $0 != .mentions && $0 != .lowPriority }
    
    init() {
        appSettings = AppSettings.volatile()
        state = RoomListFiltersState(appSettings: appSettings)
    }
    
    @Test
    func initialState() {
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == defaultFilters)
    }
    
    @Test
    func setAndUnsetFilters() {
        state.activateFilter(.unreads)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.unreads])
        #expect(state.availableFilters == [.favourites, .people, .rooms])
        state.deactivateFilter(.unreads)
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == defaultFilters)
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
        #expect(state.availableFilters == defaultFilters)
        
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
    func ignoresIncompatibleFilter() {
        state.activateFilter(.people)
        state.activateFilter(.invites)
        
        #expect(state.activeFilters == [.people])
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
        #expect(state.availableFilters == defaultFilters)
    }
    
    @Test
    func order() {
        state.activateFilter(.favourites)
        #expect(state.activeFilters == [.favourites])
        #expect(state.availableFilters == [.unreads, .people, .rooms])
        
        state.deactivateFilter(.favourites)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == defaultFilters)
        
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
        #expect(state.availableFilters == defaultFilters + [.lowPriority])
        
        state.activateFilter(.lowPriority)
        #expect(state.activeFilters == [.lowPriority])
        #expect(state.availableFilters == [.unreads, .people, .rooms])
    }
    
    // MARK: Mentions feature flag
    
    /// Don't forget to add .mentions into the mix above when enabling the feature.
    @Test
    func withMentionsFeature() {
        enableMentionsFeature()
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == [.unreads, .mentions, .favourites, .people, .rooms, .invites])
        
        state.activateFilter(.mentions)
        #expect(state.isFiltering)
        #expect(state.activeFilters == [.mentions])
        #expect(state.availableFilters == [.unreads, .favourites, .people, .rooms])
    }
    
    // MARK: - Helpers
    
    private func enableLowPriorityFeature() {
        appSettings.lowPriorityFilterEnabled = true
        state = RoomListFiltersState(appSettings: appSettings)
    }
    
    private func enableMentionsFeature() {
        appSettings.mentionsFilterEnabled = true
        state = RoomListFiltersState(appSettings: appSettings)
    }
}
