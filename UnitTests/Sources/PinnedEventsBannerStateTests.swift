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
        state.nextPin()
        XCTAssertEqual(state, originalState)
        
        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.isEmpty)
        XCTAssertNil(state.selectedPinEventID)
        XCTAssertEqual(state.displayedMessage.string, L10n.screenRoomPinnedBannerLoadingDescription)
        XCTAssertEqual(state.selectedPinIndex, 4)
        XCTAssertEqual(state.count, 5)
        XCTAssertEqual(state.bannerIndicatorDescription.string, L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(5, 5)))
    }
    
    func testLoadingToLoaded() {
        var state = PinnedEventsBannerState.loading(numbersOfEvents: 2)
        XCTAssertTrue(state.isLoading)
        state.setPinnedEventContents(["1": "test1", "2": "test2"])
        XCTAssertEqual(state, .loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinEventID: "2")))
        XCTAssertFalse(state.isLoading)
    }
    
    func testLoaded() {
        let state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2"], selectedPinEventID: "2"))
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isEmpty)
        XCTAssertEqual(state.selectedPinEventID, "2")
        XCTAssertEqual(state.displayedMessage.string, "test2")
        XCTAssertEqual(state.selectedPinIndex, 1)
        XCTAssertEqual(state.count, 2)
        XCTAssertEqual(state.bannerIndicatorDescription.string, L10n.screenRoomPinnedBannerIndicatorDescription(L10n.screenRoomPinnedBannerIndicator(2, 2)))
    }
    
    func testNextPin() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3"], selectedPinEventID: "3"))
        XCTAssertEqual(state.selectedPinEventID, "3")
        XCTAssertEqual(state.selectedPinIndex, 2)
        XCTAssertEqual(state.displayedMessage.string, "test3")
        
        state.nextPin()
        XCTAssertEqual(state.selectedPinEventID, "1")
        XCTAssertEqual(state.selectedPinIndex, 0)
        XCTAssertEqual(state.displayedMessage.string, "test1")
        
        state.nextPin()
        XCTAssertEqual(state.selectedPinEventID, "2")
        XCTAssertEqual(state.selectedPinIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test2")
    }
    
    func testSetContent() {
        var state = PinnedEventsBannerState.loaded(state: .init(pinnedEventContents: ["1": "test1", "2": "test2", "3": "test3", "4": "test4"], selectedPinEventID: "2"))
        XCTAssertEqual(state.selectedPinEventID, "2")
        XCTAssertEqual(state.selectedPinIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test2")
        XCTAssertEqual(state.count, 4)
        XCTAssertFalse(state.isEmpty)
        
        // let's remove the selected item
        state.setPinnedEventContents(["1": "test1", "3": "test3", "4": "test4"])
        // new selected item is the new latest
        XCTAssertEqual(state.selectedPinEventID, "4")
        XCTAssertEqual(state.selectedPinIndex, 2)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 3)
        XCTAssertFalse(state.isEmpty)
        
        // let's add a new item at the top
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4"])
        // selected item doesn't change
        XCTAssertEqual(state.selectedPinEventID, "4")
        // but the index is updated
        XCTAssertEqual(state.selectedPinIndex, 3)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 4)
        XCTAssertFalse(state.isEmpty)
        
        // let's add a new item at the bottom
        state.setPinnedEventContents(["0": "test0", "1": "test1", "3": "test3", "4": "test4", "5": "test5"])
        // selected item doesn't change
        XCTAssertEqual(state.selectedPinEventID, "4")
        // and index stays the same
        XCTAssertEqual(state.selectedPinIndex, 3)
        XCTAssertEqual(state.displayedMessage.string, "test4")
        XCTAssertEqual(state.count, 5)
        XCTAssertFalse(state.isEmpty)
        
        // set to tempty
        state.setPinnedEventContents([:])
        XCTAssertTrue(state.isEmpty)
        XCTAssertNil(state.selectedPinEventID)
        
        // set to one item
        state.setPinnedEventContents(["6": "test6", "7": "test7"])
        XCTAssertEqual(state.selectedPinEventID, "7")
        XCTAssertEqual(state.selectedPinIndex, 1)
        XCTAssertEqual(state.displayedMessage.string, "test7")
        XCTAssertEqual(state.count, 2)
        XCTAssertFalse(state.isEmpty)
    }
}
