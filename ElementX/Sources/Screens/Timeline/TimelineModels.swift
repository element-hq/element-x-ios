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
    case displayEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayPollForm(mode: PollFormMode)
    case displayMediaUploadPreviewScreen(mediaURLs: [URL])
    case displaySenderDetails(userID: String)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayMediaPreview(TimelineMediaPreviewViewModel)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
    case displayResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy)
    case displayThread(itemID: TimelineItemIdentifier)
    case composer(action: TimelineComposerAction)
    case hasScrolled(direction: ScrollDirection)
    case viewInRoomTimeline(eventID: String, threadRootEventID: String?)
    case displayRoom(roomID: String, via: [String])
    case displayMediaDetails(item: EventBasedMessageTimelineItemProtocol)
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
    
    case mediaTapped(itemID: TimelineItemIdentifier)
    case itemSendInfoTapped(itemID: TimelineItemIdentifier)
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case sendReadReceiptIfNeeded(TimelineItemIdentifier)
    case paginateBackwards
    case paginateForwards
    case scrollToBottom
    
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
    var isDirectOneToOneRoom = false
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
    
    let hasPredecessor: Bool
        
    // The `pinnedEventIDs` are used only to determine if an item is already pinned or not.
    // It's updated from the room info, so it's faster than using the timeline
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
    
    var mapTilerConfiguration: MapTilerConfiguration
    
    var bindings: TimelineViewStateBindings
}

struct TimelineViewStateBindings {
    var isScrolledToBottom = true
    
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
    
    var itemsDictionary = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>()
    
    var uniqueIDs: [TimelineItemIdentifier.UniqueID] {
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

extension TimelineViewState {
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
