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
    case displayEmojiPicker(itemID: String)
    case displayReportContent(itemID: String, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayMediaUploadPreviewScreen(url: URL)
    case displayRoomMemberDetails(member: RoomMemberProxyProtocol)
    case displayMessageForwarding(itemID: String)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
}

enum RoomScreenComposerMode: Equatable {
    case `default`
    case reply(itemID: String, replyDetails: TimelineItemReplyDetails)
    case edit(originalItemId: String)
    
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
    case itemAppeared(id: String)
    case itemDisappeared(id: String)
    case itemTapped(id: String)
    case linkClicked(url: URL)
    case sendMessage
    case toggleReaction(key: String, eventID: String)
    case cancelReply
    case cancelEdit
    /// Mark the entire room as read - this is heavy handed as a starting point for now.
    case markRoomAsRead
    
    case timelineItemMenu(itemID: String)
    case timelineItemMenuAction(itemID: String, action: TimelineItemMenuAction)
    
    case displayEmojiPicker(itemID: String)
    
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    
    case handlePasteOrDrop(provider: NSItemProvider)
    case tappedOnUser(userID: String)
    
    case reactionSummary(itemID: String, key: String)

    case retrySend(transactionID: String?)
    case cancelSend(transactionID: String?)
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
    
    var timelineItemMenuActionProvider: (@MainActor (_ itemId: String) -> TimelineItemMenuActions?)?
    
    var composerMode: RoomScreenComposerMode = .default
    
    var sendButtonDisabled: Bool {
        bindings.composerText.count == 0
    }

    var itemIDs: [String] {
        itemsDictionary.keys.elements
    }

    var items: [RoomTimelineItemViewModel] {
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
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomScreenErrorType>?

    var debugInfo: TimelineItemDebugInfo?
    
    var actionMenuInfo: TimelineItemActionMenuInfo?

    var sendFailedConfirmationDialogInfo: SendFailedConfirmationDialogInfo?
    
    var reactionSummaryInfo: ReactionSummaryInfo?
}

struct TimelineItemActionMenuInfo: Identifiable, Equatable {
    static func == (lhs: TimelineItemActionMenuInfo, rhs: TimelineItemActionMenuInfo) -> Bool {
        lhs.id == rhs.id
    }

    let item: EventBasedTimelineItemProtocol
    
    var id: String {
        item.id
    }
}

struct SendFailedConfirmationDialogInfo: ConfirmationDialogProtocol {
    let title = L10n.screenRoomRetrySendMenuTitle

    let transactionID: String?
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
