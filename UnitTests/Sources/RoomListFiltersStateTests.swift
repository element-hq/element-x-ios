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
    var userSettings: UserSettings
    var state: RoomListFiltersState
    /// The filters that aren't hidden behind a feature flag.
    let defaultFilters = RoomListFilter.allCases.filter { $0 != .mentions && $0 != .lowPriority }
    
    init() {
        userSettings = UserSettings.mock()
        state = RoomListFiltersState(userSettings: userSettings)
    }
    
    @Test("No filters are active and the default filters are available")
    func initialState() {
        #expect(!state.isFiltering)
        #expect(state.activeFilters == [])
        #expect(state.availableFilters == defaultFilters)
    }
    
    @Test("Activating and deactivating a filter updates the available filters")
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
    
    @Test("Filters that can't be combined with an active filter are hidden")
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
    
    @Test("Activating a filter that can't be combined with an active one is ignored")
    func ignoresIncompatibleFilter() {
        state.activateFilter(.people)
        state.activateFilter(.invites)
        
        #expect(state.activeFilters == [.people])
    }
    
    @Test("Clearing the filters brings back the default filters")
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
    
    @Test("The available filters keep their order as filters are toggled")
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
    
    @Test("The invites filter moves to the front while there are unseen invites")
    func unseenInvitesOrder() {
        state.invitesCount = 2
        state.hasUnseenInvites = true
        #expect(state.availableFilters == [.invites] + defaultFilters.filter { $0 != .invites })
        
        state.activateFilter(.unreads)
        #expect(state.availableFilters == [.favourites, .people, .rooms])
        
        state.deactivateFilter(.unreads)
        state.hasUnseenInvites = false
        #expect(state.availableFilters == defaultFilters)
    }
    
    @Test("The invites filter name shows the count when there are invites")
    func invitesCountName() {
        #expect(state.localizedName(for: .invites) == L10n.screenRoomlistFilterInvites)
        
        state.invitesCount = 5
        #expect(state.localizedName(for: .invites) == UntranslatedL10n.screenRoomlistFilterInvitesCount(5))
        #expect(state.localizedName(for: .people) == L10n.screenRoomlistFilterPeople)
    }
    
    // MARK: Low Priority feature flag
    
    /// Don't forget to add .lowPriority into the mix above when enabling the feature.
    @Test("The low priority filter is available when its feature flag is on")
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
    @Test("The mentions filter is available when its feature flag is on")
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
        userSettings.app.lowPriorityFilterEnabled = true
        state = RoomListFiltersState(userSettings: userSettings)
    }
    
    private func enableMentionsFeature() {
        userSettings.app.mentionsFilterEnabled = true
        state = RoomListFiltersState(userSettings: userSettings)
    }
}
