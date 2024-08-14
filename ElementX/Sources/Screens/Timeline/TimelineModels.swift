//
// Copyright 2022 New Vector Ltd
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

import Combine
import OrderedCollections
import SwiftUI

enum TimelineViewModelAction {
    case displayEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayPollForm(mode: PollFormMode)
    case displayMediaUploadPreviewScreen(url: URL)
    case tappedOnSenderDetails(userID: String)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
    case composer(action: TimelineComposerAction)
    case hasScrolled(direction: ScrollDirection)
}

enum TimelineViewPollAction {
    case selectOption(pollStartID: String, optionID: String)
    case end(pollStartID: String)
    case edit(pollStartID: String, poll: Poll)
}

enum TimelineAudioPlayerAction {
    case playPause(itemID: TimelineItemIdentifier)
    case seek(itemID: TimelineItemIdentifier, progress: Double)
}

enum TimelineViewAction {
    case itemAppeared(itemID: TimelineItemIdentifier)
    case itemDisappeared(itemID: TimelineItemIdentifier)
    
    case itemTapped(itemID: TimelineItemIdentifier)
    case itemSendInfoTapped(itemID: TimelineItemIdentifier)
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case sendReadReceiptIfNeeded(TimelineItemIdentifier)
    case paginateBackwards
    case paginateForwards
    case scrollToBottom
    
    case displayTimelineItemMenu(itemID: TimelineItemIdentifier)
    case handleTimelineItemMenuAction(itemID: TimelineItemIdentifier, action: TimelineItemMenuAction)
    
    case tappedOnSenderDetails(userID: String)
    case displayReactionSummary(itemID: TimelineItemIdentifier, key: String)
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    case displayReadReceipts(itemID: TimelineItemIdentifier)
    
    case handlePasteOrDrop(provider: NSItemProvider)
    case handlePollAction(TimelineViewPollAction)
    case handleAudioPlayerAction(TimelineAudioPlayerAction)
    
    /// Focus the timeline onto the specified event ID (switching to a detached timeline if needed).
    case focusOnEventID(String)
    /// Switch back to a live timeline (from a detached one).
    case focusLive
    /// The timeline scrolled to reveal the focussed item.
    case scrolledToFocussedItem
    /// The table view has loaded the first items for a new timeline.
    case hasSwitchedTimeline
    
    case hasScrolled(direction: ScrollDirection)
}

enum TimelineComposerAction {
    case setMode(mode: ComposerMode)
    case setText(plainText: String, htmlText: String?)
    case removeFocus
    case clear
}

struct TimelineViewState: BindableState {
    var roomID: String
    var members: [String: RoomMemberState] = [:]
    var typingMembers: [String] = []
    var showLoading = false
    var showReadReceipts = false
    var isEncryptedOneToOneRoom = false
    var timelineViewState: TimelineState // check the doc before changing this

    var ownUserID: String
    var canCurrentUserRedactOthers = false
    var canCurrentUserRedactSelf = false
    var canCurrentUserPin = false
    var isViewSourceEnabled: Bool
        
    // The `pinnedEventIDs` are used only to determine if an item is already pinned or not.
    // It's updated from the room info, so it's faster than using the timeline
    var pinnedEventIDs: Set<String> = []
    
    var bindings: TimelineViewStateBindings
    
    /// A closure providing the associated audio player state for an item in the timeline.
    var audioPlayerStateProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> AudioPlayerState?)?
}

struct TimelineViewStateBindings {
    var isScrolledToBottom = true
    
    /// The state of wether reactions listed on the timeline are expanded/collapsed.
    /// Key is itemID, value is the collapsed state.
    var reactionsCollapsed: [TimelineItemIdentifier: Bool]
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
    
    var alertInfo: AlertInfo<RoomScreenAlertInfoType>?
    
    var debugInfo: TimelineItemDebugInfo?
    
    var actionMenuInfo: TimelineItemActionMenuInfo?
    
    var reactionSummaryInfo: ReactionSummaryInfo?
    
    var readReceiptsSummaryInfo: ReadReceiptSummaryInfo?
}

struct TimelineItemActionMenuInfo: Equatable, Identifiable {
    static func == (lhs: TimelineItemActionMenuInfo, rhs: TimelineItemActionMenuInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    let item: EventBasedTimelineItemProtocol
    
    var id: TimelineItemIdentifier {
        item.id
    }
}

struct ReactionSummaryInfo: Identifiable {
    let reactions: [AggregatedReaction]
    let selectedKey: String
    
    var id: String {
        selectedKey
    }
}

struct ReadReceiptSummaryInfo: Identifiable {
    let orderedReceipts: [ReadReceipt]
    let id: TimelineItemIdentifier
}

enum RoomScreenAlertInfoType: Hashable {
    case audioRecodingPermissionError
    case pollEndConfirmation(String)
    case sendingFailed
    case encryptionAuthenticity(String)
}

struct RoomMemberState {
    let displayName: String?
    let avatarURL: URL?
}

/// Used as the state for the TimelineView, to avoid having the context continuously refresh the list of items on each small change.
/// Is also nice to have this as a wrapper for any state that is directly connected to the timeline.
struct TimelineState {
    var isLive = true
    var paginationState = PaginationState.initial
    
    /// The room is in the process of loading items from a new timeline (switching to/from a detached timeline).
    var isSwitchingTimelines = false
    
    struct FocussedEvent: Equatable {
        enum Appearance {
            /// The event should be shown using an animated scroll.
            case animated
            /// The event should be shown immediately, without any animation.
            case immediate
            /// The event has already been shown.
            case hasAppeared
        }

        /// The ID of the event.
        let eventID: String
        /// How the event should be shown, or whether it has already appeared.
        var appearance: Appearance
    }
    
    /// A focussed event that was navigated to via a permalink.
    var focussedEvent: FocussedEvent?
    
    // These can be removed when we have full swiftUI and moved as @State values in the view
    var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    
    var itemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>()
    
    var timelineIDs: [String] {
        itemsDictionary.keys.elements
    }
    
    var itemViewStates: [RoomTimelineItemViewState] {
        itemsDictionary.values.elements
    }
    
    func hasLoadedItem(with eventID: String) -> Bool {
        itemViewStates.contains { $0.identifier.eventID == eventID }
    }
}

enum ScrollDirection: Equatable {
    case top
    case bottom
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
    
    private(set) var selectedPinEventID: String?
    
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
