//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    var selectedPinnedEventID: String? {
        switch self {
        case .loaded(let state):
            return state.selectedPinnedEventID
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
    
    var selectedPinnedIndex: Int {
        switch self {
        case .loaded(let state):
            return state.selectedPinnedIndex
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
            return state.selectedPinnedContent
        }
    }
    
    var bannerIndicatorDescription: AttributedString {
        let index = selectedPinnedIndex + 1
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
            self = .loaded(state: .init(pinnedEventContents: pinnedEventContents, selectedPinnedEventID: pinnedEventContents.keys.last))
        case .loaded(var state):
            state.pinnedEventContents = pinnedEventContents
            self = .loaded(state: state)
        }
    }
    
    // Note that if we are setting this value, this is definitely sent from the pinned events timeline
    // so we can assume that the pinned events timeline is already loaded and we only need to set the
    // selection for the loaded state
    mutating func setSelectedPinnedEventID(_ eventID: String) {
        switch self {
        case .loaded(var state):
            state.selectedPinnedEventID = eventID
            self = .loaded(state: state)
        case .loading:
            break
        }
    }
}

struct PinnedEventsState: Equatable {
    var pinnedEventContents: OrderedDictionary<String, AttributedString> = [:] {
        didSet {
            if selectedPinnedEventID == nil, !pinnedEventContents.keys.isEmpty {
                // The default selected event should always be the last one.
                selectedPinnedEventID = pinnedEventContents.keys.last
            } else if pinnedEventContents.isEmpty {
                selectedPinnedEventID = nil
            } else if let selectedPinnedEventID, !pinnedEventContents.keys.set.contains(selectedPinnedEventID) {
                self.selectedPinnedEventID = pinnedEventContents.keys.last
            }
        }
    }
    
    var selectedPinnedEventID: String?
    
    var selectedPinnedIndex: Int {
        let defaultValue = pinnedEventContents.isEmpty ? 0 : pinnedEventContents.count - 1
        guard let selectedPinnedEventID else {
            return defaultValue
        }
        return pinnedEventContents.keys.firstIndex(of: selectedPinnedEventID) ?? defaultValue
    }
    
    var selectedPinnedContent: AttributedString {
        var content = AttributedString(" ")
        if let selectedPinnedEventID,
           let pinnedEventContent = pinnedEventContents[selectedPinnedEventID] {
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
        let currentIndex = selectedPinnedIndex
        let nextIndex = currentIndex - 1
        if nextIndex == -1 {
            selectedPinnedEventID = pinnedEventContents.keys.last
        } else {
            selectedPinnedEventID = pinnedEventContents.keys[nextIndex % pinnedEventContents.count]
        }
    }
}
