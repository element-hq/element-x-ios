//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import OrderedCollections
import SwiftUI

enum TimelineViewModelAction {
    case displayEmojiPicker(selectedEmojis: Set<String>, continuation: EmojiPickerScreenContinuation)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayNewPollForm
    case displayEditPollForm(eventID: String, poll: Poll)
    case displayMediaUploadPreviewScreen(mediaURLs: [URL])
    case displaySenderDetails(userID: String)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayMediaPreview(TimelineMediaPreviewViewModel)
    case displayLocation(StaticLocationData)
    case displayLiveLocation(sender: TimelineItemSender, initialLiveLocationShare: LiveLocationShare)
    case displayResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy)
    case displayThread(itemID: TimelineItemIdentifier)
    case composer(action: TimelineComposerAction)
    case hasScrolled(direction: ScrollDirection)
    case viewInRoomTimeline(eventID: String, threadRootEventID: String?)
    case displayRoom(roomID: String, via: [String])
    case displayMediaDetails(item: EventBasedMessageTimelineItemProtocol)
    case presentCallScreen(isVoiceCall: Bool)
}

enum TimelineViewPollAction {
    case sendResponse(pollStartID: String, answerIDs: [String])
    case end(pollStartID: String)
    case edit(pollStartID: String, poll: Poll)
}

enum TimelineAudioPlayerAction {
    case playPause(itemID: TimelineItemIdentifier)
    case seek(itemID: TimelineItemIdentifier, progress: Double)
    case changePlaybackSpeed(itemID: TimelineItemIdentifier)
}

enum TimelineViewAction {
    case itemAppeared(itemID: TimelineItemIdentifier)
    case itemDisappeared(itemID: TimelineItemIdentifier)
    
    case mediaTapped(itemID: TimelineItemIdentifier)
    case itemSendInfoTapped(itemID: TimelineItemIdentifier)
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case sendReadReceiptIfNeeded(TimelineItemIdentifier)
    case paginateBackwards
    case paginateForwards
    case scrollToBottom
    case scrollToFirstItemForCurrentDate
    case scrollToReadMarker
    case markAllAsRead
    
    case displayTimelineItemMenu(itemID: TimelineItemIdentifier)
    case handleTimelineItemMenuAction(itemID: TimelineItemIdentifier, action: TimelineItemMenuAction)
    
    case tappedOnSenderDetails(sender: TimelineItemSender)
    case displayReactionSummary(itemID: TimelineItemIdentifier, key: String)
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    case displayReadReceipts(itemID: TimelineItemIdentifier)
    case displayThread(itemID: TimelineItemIdentifier)
    
    case handlePasteOrDrop(providers: [NSItemProvider])
    case handlePollAction(TimelineViewPollAction)
    case handleAudioPlayerAction(TimelineAudioPlayerAction)
    
    case stopLiveLocationSharing(TimelineItemIdentifier)
    
    /// Focus the timeline onto the specified event ID (switching to a detached timeline if needed).
    case focusOnEventID(String)
    /// Switch back to a live timeline (from a detached one).
    case focusLive
    /// The timeline scrolled to reveal the focussed item.
    case scrolledToFocussedItem
    /// The table view has loaded the first items for a new timeline.
    case hasSwitchedTimeline
    
    case hasScrolled(direction: ScrollDirection)
    
    case displayPredecessorRoom
    case joinActiveCall(isVoiceCall: Bool)
}

enum TimelineComposerAction {
    case setMode(mode: ComposerMode)
    case setText(plainText: String, htmlText: String?)
    case setFocus
    case removeFocus
    case clear
}

struct TimelineViewState: BindableState {
    let timelineKind: TimelineKind
    var roomID: String
    var members: [String: RoomMemberState] = [:]
    var typingMembers: [String] = []
    var showLoading = false
    var showReadReceipts = false
    var isDM = false
    var timelineState: TimelineState // check the doc before changing this
    
    var ownUserID: String
    var canCurrentUserSendMessage = false
    var canCurrentUserRedactOthers = false
    var canCurrentUserRedactSelf = false
    var canCurrentUserPin = false
    var canCurrentUserKick = false
    var canCurrentUserBan = false
    
    var hideTimelineMedia: Bool
    
    var isViewSourceEnabled: Bool
    var areThreadsEnabled: Bool
    var linkPreviewsEnabled: Bool
    var jumpToReadMarkerEnabled: Bool
    
    let hasPredecessor: Bool
    
    /// The `pinnedEventIDs` are used only to determine if an item is already pinned or not.
    /// It's updated from the room info, so it's faster than using the timeline
    var pinnedEventIDs: Set<String> = []
    
    /// A closure providing the associated audio player state for an item in the timeline.
    var audioPlayerStateProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> AudioPlayerState?)?
    
    /// A closure that updates the associated pill context
    var pillContextUpdater: (@MainActor (PillContext) -> Void)?
    
    /// A closure that returns the associated room name give its id
    var roomNameForIDResolver: (@MainActor (String) -> String?)?
    
    /// A closure that returns the associated room name give its alias
    var roomNameForAliasResolver: (@MainActor (String) -> String?)?
    
    var emojiProvider: EmojiProviderProtocol
    
    var linkMetadataProvider: LinkMetadataProviderProtocol?
    
    var mapTilerSettings: MapTilerSettings
    
    var stoppedLiveLocationIDs: Set<TimelineItemIdentifier> = []
    
    var bindings: TimelineViewStateBindings
}

struct TimelineViewStateBindings {
    var isScrolledToBottom = true
    
    /// Whether the read marker (NEW banner) is currently visible in the timeline viewport.
    /// Used to hide the jump-to-unread button once the user has scrolled to the read marker.
    var isReadMarkerVisible = false
    
    /// Whether new messages have arrived while the user is scrolled away from the bottom of a
    /// live timeline. Drives the presence dot on the scroll-to-bottom button and resets when the
    /// user returns to the bottom.
    var hasNewMessagesAtBottom = false
    
    /// The timestamp of the topmost visible item, used to drive the floating date badge while scrolling.
    var floatingDate: Date?
    
    /// The state of wether reactions listed on the timeline are expanded/collapsed.
    /// Key is itemID, value is the collapsed state.
    var reactionsCollapsed: [TimelineItemIdentifier: Bool]
    
    var alertInfo: AlertInfo<TimelineAlertInfoType>?
    
    var debugInfo: TimelineItemDebugInfo?
    
    var actionMenuInfo: TimelineItemActionMenuInfo?
    
    var reactionSummaryInfo: ReactionSummaryInfo?
    
    var readReceiptsSummaryInfo: ReadReceiptSummaryInfo?
    
    var manageMemberViewModel: ManageRoomMemberSheetViewModel?
    
    var showTranslation = false
    var textToBeTranslated: String?
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

enum TimelineAlertInfoType: Hashable {
    case audioRecodingPermissionError
    case pollEndConfirmation(String)
    case sendingFailed
    case encryptionAuthenticity(String)
    case encryptionForwarder(String)
    case inviteAgain
    case unableToInvite
    case unknown
}

struct RoomMemberState {
    let displayName: String?
    let avatarURL: URL?
    let status: UserStatus
}

/// Used as the state for the TimelineView, to avoid having the context continuously refresh the list of items on each small change.
/// Is also nice to have this as a wrapper for any state that is directly connected to the timeline.
struct TimelineState {
    var isLive = true
    var paginationState = TimelinePaginationState.initial
    
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
    
    /// These can be removed when we have full swiftUI and moved as @State values in the view
    var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    var scrollToFirstItemForDatePublisher = PassthroughSubject<Void, Never>()
    var scrollToReadMarkerPublisher = PassthroughSubject<TimelineItemIdentifier.UniqueID, Never>()
    
    var itemsDictionary = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>()
    
    var uniqueIDs: [TimelineItemIdentifier.UniqueID] {
        itemsDictionary.keys.elements
    }
    
    var itemViewStates: [RoomTimelineItemViewState] {
        itemsDictionary.values.elements
    }
    
    /// The unique ID of the read marker (NEW banner) in the timeline, if present.
    /// Recomputed by ``recomputeReadMarkerUniqueID()`` whenever ``itemsDictionary`` changes.
    private(set) var readMarkerUniqueID: TimelineItemIdentifier.UniqueID?
    
    /// The user's `m.fully_read` event ID, pushed from `RoomInfo`. Used as a fallback
    /// signal when ``readMarkerUniqueID`` is nil because the marker event isn't paginated
    /// into the loaded timeline window.
    var fullyReadEventID: String?
    
    /// Recomputes ``readMarkerUniqueID`` from ``itemsDictionary``. Call after assigning a new
    /// value to ``itemsDictionary``.
    mutating func recomputeReadMarkerUniqueID() {
        readMarkerUniqueID = itemsDictionary.first { _, viewState in
            if case .readMarker = viewState.type {
                return true
            }
            return false
        }?.key
    }
    
    func hasLoadedItem(with eventID: String) -> Bool {
        itemViewStates.contains { $0.identifier.eventID == eventID }
    }
}

enum ScrollDirection: Equatable {
    case top
    case bottom
}

extension TimelineViewState {
    /// The user is at the bottom of a live timeline (no jump-to-bottom button needed).
    var isAtBottomAndLive: Bool {
        bindings.isScrolledToBottom && timelineState.isLive
    }
    
    /// Whether the scroll-to-bottom button should be shown: the user is scrolled away from the
    /// bottom of a live timeline.
    var shouldShowScrollToBottomButton: Bool {
        !isAtBottomAndLive
    }
    
    /// Whether the jump-to-read-marker button should be shown.
    ///
    /// Primary path: the SDK has materialised a virtual `ReadMarker` item in the
    /// loaded timeline window. Show while it isn't visible in the viewport.
    ///
    /// Fallback path: the marker event is older than the loaded window, so no
    /// virtual item exists. Show only when items have actually loaded AND the
    /// marker event isn't among them — if the marker IS loaded but no virtual
    /// item was inserted, the user is caught up (no events newer than the marker)
    /// and there's nothing to jump to.
    var shouldShowJumpToReadMarker: Bool {
        guard jumpToReadMarkerEnabled else { return false }
        if timelineState.readMarkerUniqueID != nil {
            return !bindings.isReadMarkerVisible
        }
        guard let fullyReadEventID = timelineState.fullyReadEventID else {
            return false
        }
        return !timelineState.itemsDictionary.isEmpty
            && !timelineState.hasLoadedItem(with: fullyReadEventID)
    }
    
    /// The string shown as the message preview.
    ///
    /// This converts the formatted body to a plain string to remove formatting
    /// and render with a consistent font size. This conversion is done to avoid
    /// showing markdown characters in the preview for messages with formatting.
    func buildMessagePreview(formattedBody: AttributedString?, plainBody: String) -> String {
        guard let formattedBody,
              let attributedString = try? NSMutableAttributedString(formattedBody, including: \.elementX) else {
            return plainBody
        }
        
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.enumerateAttributes(in: range) { attributes, range, _ in
            if let userID = attributes[.MatrixUserID] as? String {
                if let displayName = members[userID]?.displayName {
                    attributedString.replaceCharacters(in: range, with: "@\(displayName)")
                } else {
                    attributedString.replaceCharacters(in: range, with: userID)
                }
            }
            
            if attributes[.MatrixAllUsersMention] as? Bool == true {
                attributedString.replaceCharacters(in: range, with: PillUtilities.atRoom)
            }
            
            if let roomAlias = attributes[.MatrixRoomAlias] as? String {
                let roomName = roomNameForAliasResolver?(roomAlias)
                attributedString.replaceCharacters(in: range, with: PillUtilities.roomPillDisplayText(roomName: roomName, rawRoomText: roomAlias))
            }
            
            if let roomID = attributes[.MatrixRoomID] as? String {
                let roomName = roomNameForIDResolver?(roomID)
                attributedString.replaceCharacters(in: range, with: PillUtilities.roomPillDisplayText(roomName: roomName, rawRoomText: roomID))
            }
            
            if let eventOnRoomID = attributes[.MatrixEventOnRoomID] as? EventOnRoomIDAttribute.Value {
                let roomID = eventOnRoomID.roomID
                let roomName = roomNameForIDResolver?(roomID)
                attributedString.replaceCharacters(in: range, with: PillUtilities.eventPillDisplayText(roomName: roomName, rawRoomText: roomID))
            }
            
            if let eventOnRoomAlias = attributes[.MatrixEventOnRoomAlias] as? EventOnRoomAliasAttribute.Value {
                let roomAlias = eventOnRoomAlias.alias
                let roomName = roomNameForAliasResolver?(roomAlias)
                attributedString.replaceCharacters(in: range, with: PillUtilities.eventPillDisplayText(roomName: roomName, rawRoomText: eventOnRoomAlias.alias))
            }
        }
        
        return attributedString.string
    }
}
