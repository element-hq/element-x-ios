//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    case displayResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, itemID: TimelineItemIdentifier)
    case composer(action: TimelineComposerAction)
    case hasScrolled(direction: ScrollDirection)
    case viewInRoomTimeline(eventID: String)
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
    case setOpenURLAction(OpenURLAction)
}

enum TimelineComposerAction {
    case setMode(mode: ComposerMode)
    case setText(plainText: String, htmlText: String?)
    case removeFocus
    case clear
}

struct TimelineViewState: BindableState {
    let isPinnedEventsTimeline: Bool
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
    
    /// an openURL closure which opens URLs first using the App's environment rather than skipping out to external apps
    var openURL: OpenURLAction?
    
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
