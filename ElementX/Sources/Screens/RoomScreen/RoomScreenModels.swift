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

enum RoomScreenViewModelAction {
    case displayRoomDetails
    case displayEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayPollForm(mode: PollFormMode)
    case displayMediaUploadPreviewScreen(url: URL)
    case displayRoomMemberDetails(userID: String)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
    case composer(action: RoomScreenComposerAction)
    case displayCallScreen
}

enum RoomScreenComposerMode: Equatable {
    case `default`
    case reply(itemID: TimelineItemIdentifier, replyDetails: TimelineItemReplyDetails, isThread: Bool)
    case edit(originalItemId: TimelineItemIdentifier)
    case recordVoiceMessage(state: AudioRecorderState)
    case previewVoiceMessage(state: AudioPlayerState, waveform: WaveformSource, isUploading: Bool)

    var isEdit: Bool {
        switch self {
        case .edit:
            return true
        default:
            return false
        }
    }

    var isTextEditingEnabled: Bool {
        switch self {
        case .default, .reply, .edit:
            return true
        case .recordVoiceMessage, .previewVoiceMessage:
            return false
        }
    }
    
    var isLoadingReply: Bool {
        switch self {
        case .reply(_, let replyDetails, _):
            switch replyDetails {
            case .loading:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    var replyEventID: String? {
        switch self {
        case .reply(let itemID, _, _):
            return itemID.eventID
        default:
            return nil
        }
    }
    
    var isComposingNewMessage: Bool {
        switch self {
        case .default, .reply:
            return true
        default:
            return false
        }
    }
}

enum RoomScreenViewPollAction {
    case selectOption(pollStartID: String, optionID: String)
    case end(pollStartID: String)
    case edit(pollStartID: String, poll: Poll)
}

enum RoomScreenAudioPlayerAction {
    case playPause(itemID: TimelineItemIdentifier)
    case seek(itemID: TimelineItemIdentifier, progress: Double)
}

enum RoomScreenViewAction {
    case itemAppeared(itemID: TimelineItemIdentifier)
    case itemDisappeared(itemID: TimelineItemIdentifier)
    
    case itemTapped(itemID: TimelineItemIdentifier)
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case sendReadReceiptIfNeeded(TimelineItemIdentifier)
    case paginateBackwards
    case paginateForwards
    case scrollToBottom
    
    case displayTimelineItemMenu(itemID: TimelineItemIdentifier)
    case handleTimelineItemMenuAction(itemID: TimelineItemIdentifier, action: TimelineItemMenuAction)
    
    case displayRoomDetails
    case displayRoomMemberDetails(userID: String)
    case displayReactionSummary(itemID: TimelineItemIdentifier, key: String)
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    case displayReadReceipts(itemID: TimelineItemIdentifier)
    case displayCall
    
    case handlePasteOrDrop(provider: NSItemProvider)
    case handlePollAction(RoomScreenViewPollAction)
    case handleAudioPlayerAction(RoomScreenAudioPlayerAction)
    
    /// Focus the timeline onto the specified event ID (switching to a detached timeline if needed).
    case focusOnEventID(String)
    /// Switch back to a live timeline (from a detached one).
    case focusLive
    /// The timeline scrolled to reveal the focussed item.
    case scrolledToFocussedItem
    /// The table view has loaded the first items for a new timeline.
    case hasSwitchedTimeline
    
    case hasScrolled(direction: ScrollDirection)
    case tappedPinnedEventsBanner
    case viewAllPins
}

enum RoomScreenComposerAction {
    case setMode(mode: RoomScreenComposerMode)
    case setText(plainText: String, htmlText: String?)
    case removeFocus
    case clear
    case saveDraft
    case loadDraft
}

struct RoomScreenViewState: BindableState {
    var roomID: String
    var roomTitle = ""
    var roomAvatar: RoomAvatar
    var members: [String: RoomMemberState] = [:]
    var typingMembers: [String] = []
    var showLoading = false
    var showReadReceipts = false
    var isEncryptedOneToOneRoom = false
    var timelineViewState: TimelineViewState // check the doc before changing this

    var ownUserID: String
    var canCurrentUserRedactOthers = false
    var canCurrentUserRedactSelf = false
    var canCurrentUserPin = false
    var isViewSourceEnabled: Bool
    
    var isPinningEnabled = false
    var lastScrollDirection: ScrollDirection?
    
    // The `pinnedEventIDs` are used only to determine if an item is already pinned or not.
    // It's updated from the room info, so it's faster than using the timeline
    var pinnedEventIDs: Set<String> = []
    // This is used to control the banner
    var pinnedEventsState = PinnedEventsState()
    
    var shouldShowPinnedEventsBanner: Bool {
        isPinningEnabled && !pinnedEventsState.pinnedEventContents.isEmpty && lastScrollDirection != .top
    }
    
    var canJoinCall = false
    var hasOngoingCall = false
    
    var bindings: RoomScreenViewStateBindings
    
    /// A closure providing the associated audio player state for an item in the timeline.
    var audioPlayerStateProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> AudioPlayerState?)?
}

struct RoomScreenViewStateBindings {
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
}

struct RoomMemberState {
    let displayName: String?
    let avatarURL: URL?
}

/// Used as the state for the TimelineView, to avoid having the context continuously refresh the list of items on each small change.
/// Is also nice to have this as a wrapper for any state that is directly connected to the timeline.
struct TimelineViewState {
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
                selectedPinEventID = pinnedEventContents.keys.last
            } else if pinnedEventContents.isEmpty {
                selectedPinEventID = nil
            } else if let selectedPinEventID, !pinnedEventContents.keys.set.contains(selectedPinEventID) {
                self.selectedPinEventID = pinnedEventContents.firstNonNil { $0.key }
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
        guard let selectedPinEventID,
              var content = pinnedEventContents[selectedPinEventID] else {
            return AttributedString()
        }
        content.font = .compound.bodyMD
        return content
    }
    
    var bannerIndicatorDescription: AttributedString {
        let index = selectedPinIndex + 1
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.screenRoomPinnedBannerIndicatorDescription(boldPlaceholder))
        var boldString = AttributedString(L10n.screenRoomPinnedBannerIndicator(index, pinnedEventContents.count))
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }
    
    mutating func nextPin() {
        guard !pinnedEventContents.isEmpty else {
            return
        }
        let currentIndex = selectedPinIndex
        let nextIndex = (currentIndex + 1) % pinnedEventContents.count
        selectedPinEventID = pinnedEventContents.keys[nextIndex]
    }
}
