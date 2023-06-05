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

enum RoomScreenViewModelAction {
    case displayRoomDetails
    case displayMediaViewer(file: MediaFileHandleProxy, title: String?)
    case displayEmojiPicker(itemID: String)
    case displayReportContent(itemID: String, senderID: String)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayMediaUploadPreviewScreen(url: URL)
    case displayRoomMemberDetails(member: RoomMemberProxyProtocol)
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
    case itemDoubleTapped(id: String)
    case linkClicked(url: URL)
    case sendMessage
    case sendReaction(key: String, eventID: String)
    case cancelReply
    case cancelEdit
    /// Mark the entire room as read - this is heavy handed as a starting point for now.
    case markRoomAsRead
    case contextMenuAction(itemID: String, action: TimelineItemContextMenuAction)
    
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    
    case handlePasteOrDrop(provider: NSItemProvider)
    case tappedOnUser(userID: String)
}

struct RoomScreenViewState: BindableState {
    var roomId: String
    var roomTitle = ""
    var roomAvatarURL: URL?
    var items: [RoomTimelineViewProvider] = []
    var canBackPaginate = true
    var isBackPaginating = false
    var showLoading = false
    var timelineStyle: TimelineStyle
    
    var bindings: RoomScreenViewStateBindings
    
    var contextMenuActionProvider: (@MainActor (_ itemId: String) -> TimelineItemContextMenuActions?)?
    
    var composerMode: RoomScreenComposerMode = .default
    
    var sendButtonDisabled: Bool {
        bindings.composerText.count == 0
    }
    
    let scrollToBottomPublisher = PassthroughSubject<Void, Never>()
}

struct RoomScreenViewStateBindings {
    var composerText: String
    var composerFocused: Bool
    
    var scrollToBottomButtonVisible = false
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomScreenErrorType>?

    var debugInfo: TimelineItemDebugInfo?
}

enum RoomScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// A specific error message shown in a toast.
    case toast(String)
}
