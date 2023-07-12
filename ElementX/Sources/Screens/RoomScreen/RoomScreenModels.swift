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
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayMediaUploadPreviewScreen(url: URL)
    case displayRoomMemberDetails(member: RoomMemberProxyProtocol)
    case displayMessageForwarding(itemID: TimelineItemIdentifier)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
}

enum RoomScreenComposerMode: Equatable {
    case `default`
    case reply(itemID: TimelineItemIdentifier, replyDetails: TimelineItemReplyDetails)
    case edit(originalItemId: TimelineItemIdentifier)
    
    var isEdit: Bool {
        switch self {
        case .edit:
            return true
        default:
            return false
        }
    }
}

enum RoomScreenViewAction {
    case displayRoomDetails
    case paginateBackwards
    case itemAppeared(itemID: TimelineItemIdentifier)
    case itemDisappeared(itemID: TimelineItemIdentifier)
    case itemTapped(itemID: TimelineItemIdentifier)
    case linkClicked(url: URL)
    case sendMessage
    case toggleReaction(key: String, itemID: TimelineItemIdentifier)
    case cancelReply
    case cancelEdit
    /// Mark the entire room as read - this is heavy handed as a starting point for now.
    case markRoomAsRead
    
    case timelineItemMenu(itemID: TimelineItemIdentifier)
    case timelineItemMenuAction(itemID: TimelineItemIdentifier, action: TimelineItemMenuAction)
    
    case displayEmojiPicker(itemID: TimelineItemIdentifier)
    
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    
    case handlePasteOrDrop(provider: NSItemProvider)
    case tappedOnUser(userID: String)
    
    case reactionSummary(itemID: TimelineItemIdentifier, key: String)

    case retrySend(itemID: TimelineItemIdentifier)
    case cancelSend(itemID: TimelineItemIdentifier)
}

struct RoomScreenViewState: BindableState {
    var roomId: String
    var roomTitle = ""
    var roomAvatarURL: URL?
    var itemsDictionary = OrderedDictionary<String, RoomTimelineItemViewModel>()
    var members: [String: RoomMemberState] = [:]
    var canBackPaginate = true
    var isBackPaginating = false
    var showLoading = false
    var timelineStyle: TimelineStyle
    var readReceiptsEnabled: Bool
    var isEncryptedOneToOneRoom = false
    
    var bindings: RoomScreenViewStateBindings
    
    var timelineItemMenuActionProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> TimelineItemMenuActions?)?
    
    var composerMode: RoomScreenComposerMode = .default
    
    var sendButtonDisabled: Bool {
        bindings.composerText.count == 0
    }

    var timelineIDs: [String] {
        itemsDictionary.keys.elements
    }

    var itemViewModels: [RoomTimelineItemViewModel] {
        itemsDictionary.values.elements
    }
    
    let scrollToBottomPublisher = PassthroughSubject<Void, Never>()
}

struct RoomScreenViewStateBindings {
    var composerText: String
    var composerFocused: Bool
    
    var scrollToBottomButtonVisible = false
    var showAttachmentPopover = false {
        didSet {
            composerFocused = false
        }
    }
    
    /// The state of wether reactions listed on the timeline are expanded/collapsed.
    /// Key is itemID, value is the collapsed state.
    var reactionsCollapsed: [TimelineItemIdentifier: Bool]
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomScreenErrorType>?

    var debugInfo: TimelineItemDebugInfo?
    
    var actionMenuInfo: TimelineItemActionMenuInfo?

    var sendFailedConfirmationDialogInfo: SendFailedConfirmationDialogInfo?
    
    var reactionSummaryInfo: ReactionSummaryInfo?
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
