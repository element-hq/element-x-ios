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
import SwiftUI
import UIKit

import OrderedCollections

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
    case displayRoomMemberDetails(member: RoomMemberProxyProtocol)
    case displayMessageForwarding(itemID: TimelineItemIdentifier)
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
}

enum RoomScreenViewPollAction {
    case selectOption(pollStartID: String, optionID: String)
    case end(pollStartID: String)
    case edit(pollStartID: String, poll: Poll)
}

enum RoomScreenViewAudioAction {
    case playPause(itemID: TimelineItemIdentifier)
    case seek(itemID: TimelineItemIdentifier, progress: Double)
}

enum RoomScreenViewAction {
    case displayRoomDetails
    case itemAppeared(itemID: TimelineItemIdentifier)
    case itemDisappeared(itemID: TimelineItemIdentifier)
    case itemTapped(itemID: TimelineItemIdentifier)
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case sendReadReceiptIfNeeded(TimelineItemIdentifier)
    case paginateBackwards
    
    case timelineItemMenu(itemID: TimelineItemIdentifier)
    case timelineItemMenuAction(itemID: TimelineItemIdentifier, action: TimelineItemMenuAction)
    
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    
    case handlePasteOrDrop(provider: NSItemProvider)
    
    case tappedOnUser(userID: String)
    
    case reactionSummary(itemID: TimelineItemIdentifier, key: String)
    
    case retrySend(itemID: TimelineItemIdentifier)
    case cancelSend(itemID: TimelineItemIdentifier)
    
    case showReadReceipts(itemID: TimelineItemIdentifier)
    
    case scrolledToBottom
    
    case poll(RoomScreenViewPollAction)
    
    case audio(RoomScreenViewAudioAction)
    
    case presentCall
}

enum RoomScreenComposerAction {
    case setMode(mode: RoomScreenComposerMode)
    case setText(text: String)
    case removeFocus
    case clear
}

struct RoomScreenViewState: BindableState {
    var roomID: String
    var roomTitle = ""
    var roomAvatarURL: URL?
    var members: [String: RoomMemberState] = [:]
    var showLoading = false
    var timelineStyle: TimelineStyle
    var readReceiptsEnabled: Bool
    var isEncryptedOneToOneRoom = false
    var timelineViewState = TimelineViewState() // check the doc before changing this
    var swiftUITimelineEnabled = false

    var ownUserID: String
    
    var canJoinCall = false
    var hasOngoingCall = false
    
    var bindings: RoomScreenViewStateBindings
    
    /// A closure providing the actions to show when long pressing on an item in the timeline.
    var timelineItemMenuActionProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> TimelineItemMenuActions?)?
    
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
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomScreenErrorType>?
    
    /// An alert info for confirmation actions (e.g. ending a poll)
    var confirmationAlertInfo: AlertInfo<UUID>?
    
    var debugInfo: TimelineItemDebugInfo?
    
    var actionMenuInfo: TimelineItemActionMenuInfo?
    
    var sendFailedConfirmationDialogInfo: SendFailedConfirmationDialogInfo?
    
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

struct SendFailedConfirmationDialogInfo: ConfirmationDialogProtocol {
    let title = L10n.screenRoomRetrySendMenuTitle
    
    let itemID: TimelineItemIdentifier
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

enum RoomScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// A specific error message shown in a toast.
    case toast(String)
}

struct RoomMemberState {
    let displayName: String?
    let avatarURL: URL?
}

/// Used as the state for the TimelineView, to avoid having the context continuously refresh the list of items on each small change.
/// Is also nice to have this as a wrapper for any state that is directly connected to the timeline.
struct TimelineViewState {
    var canBackPaginate = true
    var isBackPaginating = false
    
    // These can be removed when we have full swiftUI and moved as @State values in the view
    var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    
    var itemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>()
    
    var renderedTimelineIDs = [String]()
    var pendingTimelineIDs = [String]()
    
    var timelineIDs: [String] {
        itemsDictionary.keys.elements
    }
    
    var itemViewStates: [RoomTimelineItemViewState] {
        renderedTimelineIDs.compactMap { itemsDictionary[$0] }
    }
}
