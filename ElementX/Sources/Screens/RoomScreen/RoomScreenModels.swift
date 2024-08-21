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

import Foundation
import OrderedCollections

enum RoomScreenViewModelAction {
    case focusEvent(eventID: String)
    case displayPinnedEventsTimeline
    case displayRoomDetails
    case displayCall
    case removeComposerFocus
}

enum RoomScreenViewAction {
    case tappedPinnedEventsBanner
    case viewAllPins
    case displayRoomDetails
    case displayCall
}

struct RoomScreenViewState: BindableState {
    var roomTitle = ""
    var roomAvatar: RoomAvatar
    
    var lastScrollDirection: ScrollDirection?
    var isPinningEnabled = false
    // This is used to control the banner
    var pinnedEventsBannerState: PinnedEventsBannerState = .loading(numbersOfEvents: 0)
    var shouldShowPinnedEventsBanner: Bool {
        isPinningEnabled && !pinnedEventsBannerState.isEmpty && lastScrollDirection != .top
    }
    
    var canJoinCall = false
    var hasOngoingCall: Bool
    var shouldShowCallButton = true
    
    var bindings: RoomScreenViewStateBindings
}

struct RoomScreenViewStateBindings { }

enum PinnedEventsBannerState: Equatable {
    case loading(numbersOfEvents: Int)
    case loaded(state: PinnedEventsState)
    
    var isEmpty: Bool {
        switch self {
        case .loaded(let state):
            return state.pinnedEventContents.isEmpty
        case .loading(let numberOfEvents):
            return numberOfEvents == 0
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var selectedPinEventID: String? {
        switch self {
        case .loaded(let state):
            return state.selectedPinEventID
        default:
            return nil
        }
    }
    
    var count: Int {
        switch self {
        case .loaded(let state):
            return state.pinnedEventContents.count
        case .loading(let numberOfEvents):
            return numberOfEvents
        }
    }
    
    var selectedPinIndex: Int {
        switch self {
        case .loaded(let state):
            return state.selectedPinIndex
        case .loading(let numbersOfEvents):
            // We always want the index to be the last one when loading, since is the default one.
            return numbersOfEvents - 1
        }
    }
    
    var displayedMessage: AttributedString {
        switch self {
        case .loading:
            return AttributedString(L10n.screenRoomPinnedBannerLoadingDescription)
        case .loaded(let state):
            return state.selectedPinContent
        }
    }
    
    var bannerIndicatorDescription: AttributedString {
        let index = selectedPinIndex + 1
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenRoomPinnedBannerIndicatorDescription(boldPlaceholder))
        var boldString = AttributedString(L10n.screenRoomPinnedBannerIndicator(index, count))
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }
    
    mutating func previousPin() {
        switch self {
        case .loaded(var state):
            state.previousPin()
            self = .loaded(state: state)
        default:
            break
        }
    }
    
    mutating func setPinnedEventContents(_ pinnedEventContents: OrderedDictionary<String, AttributedString>) {
        switch self {
        case .loading:
            // The default selected event should always be the last one.
            self = .loaded(state: .init(pinnedEventContents: pinnedEventContents, selectedPinEventID: pinnedEventContents.keys.last))
        case .loaded(var state):
            state.pinnedEventContents = pinnedEventContents
            self = .loaded(state: state)
        }
    }
    
    // Note that if we are setting this value, this is definitely sent from the pinned events timeline so we can assume that the pinned events timeline is already loaded, so we only need to set the selection for the loaded state
    mutating func setSelectedPinEventID(_ eventID: String) {
        switch self {
        case .loaded(var state):
            state.selectedPinEventID = eventID
            self = .loaded(state: state)
        case .loading:
            break
        }
    }
}

struct PinnedEventsState: Equatable {
    var pinnedEventContents: OrderedDictionary<String, AttributedString> = [:] {
        didSet {
            if selectedPinEventID == nil, !pinnedEventContents.keys.isEmpty {
                // The default selected event should always be the last one.
                selectedPinEventID = pinnedEventContents.keys.last
            } else if pinnedEventContents.isEmpty {
                selectedPinEventID = nil
            } else if let selectedPinEventID, !pinnedEventContents.keys.set.contains(selectedPinEventID) {
                self.selectedPinEventID = pinnedEventContents.keys.last
            }
        }
    }
    
    var selectedPinEventID: String?
    
    var selectedPinIndex: Int {
        let defaultValue = pinnedEventContents.isEmpty ? 0 : pinnedEventContents.count - 1
        guard let selectedPinEventID else {
            return defaultValue
        }
        return pinnedEventContents.keys.firstIndex(of: selectedPinEventID) ?? defaultValue
    }
    
    var selectedPinContent: AttributedString {
        var content = AttributedString(" ")
        if let selectedPinEventID,
           let pinnedEventContent = pinnedEventContents[selectedPinEventID] {
            content = pinnedEventContent
        }
        content.font = .compound.bodyMD
        content.link = nil
        return content
    }
    
    mutating func previousPin() {
        guard !pinnedEventContents.isEmpty else {
            return
        }
        let currentIndex = selectedPinIndex
        let nextIndex = currentIndex - 1
        if nextIndex == -1 {
            selectedPinEventID = pinnedEventContents.keys.last
        } else {
            selectedPinEventID = pinnedEventContents.keys[nextIndex % pinnedEventContents.count]
        }
    }
}
