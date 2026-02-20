//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct PinnedEventsBannerStateTests {
    @Test
    func empty() {
        var state = PinnedEventsBannerState.loading(numbersOfEvents: 0)
        #expect(state.isEmpty)
        
        state = .loaded(state: .init())
        #expect(state.isEmpty)
    }
    
    @Test
    func loading() {
        let originalState = PinnedEventsBannerState.loading(numbersOfEvents: 5)
        
        var state = originalState
        // This should not affect the state when loading
        state.previousPin()
        #expect(state == originalState)
        
        #expect(state.isLoading)
        #expect(!state.isEmpty)
        #expect(state.selectedPinnedEventID == nil)
        #expect(state.displayedMessage.string == L10n.screenRoomPinnedBannerLoadingDescription)
        #expect(state.selectedPinnedIndex == 4)
        #expect(state.count == 5)
        #expect(state.bannerIndicatorDescription.string == L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(5, 5)))
    }
    
    @Test
    func loadingToLoaded() {
        var state = PinnedEventsBannerState.loading(numbersOfEvents: 2)
        #expect(state.isLoading)
        state.setPinnedEventContents(["1": "test1", "2": "test2"])
        #expect(state == .loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinnedEventID: "2")))
        #expect(!state.isLoading)
    }
    
    @Test
    func loaded() {
        let state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinnedEventID: "2"))
        #expect(!state.isLoading)
        #expect(!state.isEmpty)
        #expect(state.selectedPinnedEventID == "2")
        #expect(state.displayedMessage.string == "test2")
        #expect(state.selectedPinnedIndex == 1)
        #expect(state.count == 2)
        #expect(state.bannerIndicatorDescription.string == L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(2, 2)))
    }
    
    @Test
    func previousPin() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3"], selectedPinnedEventID: "1"))
        #expect(state.selectedPinnedEventID == "1")
        #expect(state.selectedPinnedIndex == 0)
        #expect(state.displayedMessage.string == "test1")
        
        state.previousPin()
        #expect(state.selectedPinnedEventID == "3")
        #expect(state.selectedPinnedIndex == 2)
        #expect(state.displayedMessage.string == "test3")
        
        state.previousPin()
        #expect(state.selectedPinnedEventID == "2")
        #expect(state.selectedPinnedIndex == 1)
        #expect(state.displayedMessage.string == "test2")
    }
    
    @Test
    func setContent() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3", "4": "test4"], selectedPinnedEventID: "2"))
        #expect(state.selectedPinnedEventID == "2")
        #expect(state.selectedPinnedIndex == 1)
        #expect(state.displayedMessage.string == "test2")
        #expect(state.count == 4)
        #expect(!state.isEmpty)
        
        // let's remove the selected item
        state.setPinnedEventContents(["1": "test1", "3": "test3", "4": "test4"])
        // new selected item is the new latest
        #expect(state.selectedPinnedEventID == "4")
        #expect(state.selectedPinnedIndex == 2)
        #expect(state.displayedMessage.string == "test4")
        #expect(state.count == 3)
        #expect(!state.isEmpty)
        
        // let's add a new item at the top
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4"])
        // selected item doesn't change
        #expect(state.selectedPinnedEventID == "4")
        // but the index is updated
        #expect(state.selectedPinnedIndex == 3)
        #expect(state.displayedMessage.string == "test4")
        #expect(state.count == 4)
        #expect(!state.isEmpty)
        
        // let's add a new item at the bottom
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4", "5": "test5"])
        // selected item doesn't change
        #expect(state.selectedPinnedEventID == "4")
        // and index stays the same
        #expect(state.selectedPinnedIndex == 3)
        #expect(state.displayedMessage.string == "test4")
        #expect(state.count == 5)
        #expect(!state.isEmpty)
        
        // set to tempty
        state.setPinnedEventContents([:])
        #expect(state.isEmpty)
        #expect(state.selectedPinnedEventID == nil)
        
        // set to one item
        state.setPinnedEventContents(["6": "test6", "7": "test7"])
        #expect(state.selectedPinnedEventID == "7")
        #expect(state.selectedPinnedIndex == 1)
        #expect(state.displayedMessage.string == "test7")
        #expect(state.count == 2)
        #expect(!state.isEmpty)
    }
}
