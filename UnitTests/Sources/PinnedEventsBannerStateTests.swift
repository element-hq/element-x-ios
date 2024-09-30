//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class PinnedEventsBannerStateTests: XCTestCase {
    func testEmpty() {
        var state = PinnedEventsBannerState.loading(numbersOfEvents: 0)
        XCTAssertTrue(state.isEmpty)
        
        state = .loaded(state: .init())
        XCTAssertTrue(state.isEmpty)
    }
    
    func testLoading() {
        let originalState = PinnedEventsBannerState.loading(numbersOfEvents: 5)
        
        var state = originalState
        // This should not affect the state when loading
        state.previousPin()
        XCTAssertEqual(state, originalState)
        
        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.isEmpty)
        XCTAssertNil(state.selectedPinnedEventID)
        XCTAssertEqual(state.displayedMessage.string, L10n.screenRoomPinnedBannerLoadingDescription)
        XCTAssertEqual(state.selectedPinnedIndex, 4)
        XCTAssertEqual(state.count, 5)
        XCTAssertEqual(state.bannerIndicatorDescription.string, L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(5, 5)))
    }
    
    func testLoadingToLoaded() {
        var state = PinnedEventsBannerState.loading(numbersOfEvents: 2)
        XCTAssertTrue(state.isLoading)
        state.setPinnedEventContents(["1": "test1", "2": "test2"])
        XCTAssertEqual(state, .loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinnedEventID: "2")))
        XCTAssertFalse(state.isLoading)
    }
    
    func testLoaded() {
        let state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinnedEventID: "2"))
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isEmpty)
        XCTAssertEqual(state.selectedPinnedEventID, "2")
        XCTAssertEqual(state.displayedMessage.string, "test2")
        XCTAssertEqual(state.selectedPinnedIndex, 1)
        XCTAssertEqual(state.count, 2)
        XCTAssertEqual(state.bannerIndicatorDescription.string, L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(2, 2)))
    }
    
    func testPreviousPin() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3"], selectedPinnedEventID: "1"))
        XCTAssertEqual(state.selectedPinnedEventID, "1")
        XCTAssertEqual(state.selectedPinnedIndex, 0)
        XCTAssertEqual(state.displayedMessage.string, "test1")
        
        state.previousPin()
        XCTAssertEqual(state.selectedPinnedEventID, "3")
        XCTAssertEqual(state.selectedPinnedIndex, 2)
        XCTAssertEqual(state.displayedMessage.string, "test3")
        
        state.previousPin()
        XCTAssertEqual(state.selectedPinnedEventID, "2")
        XCTAssertEqual(state.selectedPinnedIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test2")
    }
    
    func testSetContent() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3", "4": "test4"], selectedPinnedEventID: "2"))
        XCTAssertEqual(state.selectedPinnedEventID, "2")
        XCTAssertEqual(state.selectedPinnedIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test2")
        XCTAssertEqual(state.count, 4)
        XCTAssertFalse(state.isEmpty)
        
        // let's remove the selected item
        state.setPinnedEventContents(["1": "test1", "3": "test3", "4": "test4"])
        // new selected item is the new latest
        XCTAssertEqual(state.selectedPinnedEventID, "4")
        XCTAssertEqual(state.selectedPinnedIndex, 2)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 3)
        XCTAssertFalse(state.isEmpty)
        
        // let's add a new item at the top
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4"])
        // selected item doesn't change
        XCTAssertEqual(state.selectedPinnedEventID, "4")
        // but the index is updated
        XCTAssertEqual(state.selectedPinnedIndex, 3)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 4)
        XCTAssertFalse(state.isEmpty)
        
        // let's add a new item at the bottom
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4", "5": "test5"])
        // selected item doesn't change
        XCTAssertEqual(state.selectedPinnedEventID, "4")
        // and index stays the same
        XCTAssertEqual(state.selectedPinnedIndex, 3)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 5)
        XCTAssertFalse(state.isEmpty)
        
        // set to tempty
        state.setPinnedEventContents([:])
        XCTAssertTrue(state.isEmpty)
        XCTAssertNil(state.selectedPinnedEventID)
        
        // set to one item
        state.setPinnedEventContents(["6": "test6", "7": "test7"])
        XCTAssertEqual(state.selectedPinnedEventID, "7")
        XCTAssertEqual(state.selectedPinnedIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test7")
        XCTAssertEqual(state.count, 2)
        XCTAssertFalse(state.isEmpty)
    }
}
