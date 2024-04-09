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
import Foundation
import UIKit

enum HomeScreenViewModelAction {
    case presentRoom(roomIdentifier: String)
    case presentRoomDetails(roomIdentifier: String)
    case roomLeft(roomIdentifier: String)
    case presentSecureBackupSettings
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentStartChatScreen
    case presentInvitesScreen
    case presentGlobalSearch
    case presentRoomDirectorySearch
    case logout
}

enum HomeScreenViewAction {
    case selectRoom(roomIdentifier: String)
    case showRoomDetails(roomIdentifier: String)
    case leaveRoom(roomIdentifier: String)
    case confirmLeaveRoom(roomIdentifier: String)
    case showSettings
    case startChat
    case confirmRecoveryKey
    case skipRecoveryKeyConfirmation
    case updateVisibleItemRange(range: Range<Int>, isScrolling: Bool)
    case selectInvites
    case globalSearch
    case markRoomAsUnread(roomIdentifier: String)
    case markRoomAsRead(roomIdentifier: String)
    case markRoomAsFavourite(roomIdentifier: String, isFavourite: Bool)
    case selectRoomDirectorySearch
    
    case acceptInvite(roomIdentifier: String)
    case declineInvite(roomIdentifier: String)
}

enum HomeScreenRoomListMode: CustomStringConvertible {
    case migration
    case skeletons
    case empty
    case rooms
    
    var description: String {
        switch self {
        case .migration:
            return "Showing account migration"
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .rooms:
            return "Showing rooms"
        }
    }
}

enum SecurityBannerMode {
    case none
    case dismissed
    case recoveryKeyConfirmation
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var securityBannerMode = SecurityBannerMode.none
    var requiresExtraAccountSetup = false
        
    var rooms: [HomeScreenRoom] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    var hasPendingInvitations = false
    var hasUnreadPendingInvitations = false
    
    var isRoomDirectorySearchEnabled = false
    
    var selectedRoomID: String?
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        return rooms
    }
    
    var bindings = HomeScreenViewStateBindings()
    
    var placeholderRooms: [HomeScreenRoom] {
        (1...10).map { _ in
            HomeScreenRoom.placeholder()
        }
    }
    
    // Used to hide all the rooms when the search field is focused and the query is empty
    var shouldHideRoomList: Bool {
        bindings.isSearchFieldFocused && bindings.searchQuery.isEmpty
    }
    
    var shouldShowEmptyFilterState: Bool {
        !bindings.isSearchFieldFocused && bindings.filtersState.isFiltering && visibleRooms.isEmpty
    }
}

struct HomeScreenViewStateBindings {
    var filtersState = RoomListFiltersState()
    var searchQuery = ""
    var isSearchFieldFocused = false
    
    var alertInfo: AlertInfo<UUID>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
}

struct HomeScreenRoom: Identifiable, Equatable {
    enum RoomType {
        case placeholder
        case room
        case invite
    }
    
    struct InviterDetails: Equatable {
        let userID: String
        let displayName: String?
        let avatarURL: URL?
    }
    
    static let placeholderLastMessage = AttributedString("Hidden last message")
        
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    let type: RoomType
    
    let badges: Badges
    struct Badges: Equatable {
        let isDotShown: Bool
        let isMentionShown: Bool
        let isMuteShown: Bool
        let isCallShown: Bool
    }
    
    let name: String
    
    let isDirect: Bool
    
    let isHighlighted: Bool
    
    let isFavourite: Bool
    
    let timestamp: String?
    
    let lastMessage: AttributedString?
    
    let avatarURL: URL?
    
    let inviter: InviterDetails?
    
    let canonicalAlias: String?
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomId: nil,
                       type: .placeholder,
                       badges: .init(isDotShown: false, isMentionShown: false, isMuteShown: false, isCallShown: false),
                       name: "Placeholder room name",
                       isDirect: false,
                       isHighlighted: false,
                       isFavourite: false,
                       timestamp: "Now",
                       lastMessage: placeholderLastMessage,
                       avatarURL: nil,
                       inviter: nil,
                       canonicalAlias: nil)
    }
}

extension HomeScreenRoom {
    init(details: RoomSummaryDetails, invalidated: Bool, hideUnreadMessagesBadge: Bool) {
        let identifier = invalidated ? "invalidated-" + details.id : details.id
        
        let hasUnreadMessages = hideUnreadMessagesBadge ? false : details.hasUnreadMessages
        
        let isDotShown = hasUnreadMessages || details.hasUnreadMentions || details.hasUnreadNotifications || details.isMarkedUnread
        let isMentionShown = details.hasUnreadMentions && !details.isMuted
        let isMuteShown = details.isMuted
        let isCallShown = details.hasOngoingCall
        let isHighlighted = details.isMarkedUnread || (!details.isMuted && (details.hasUnreadNotifications || details.hasUnreadMentions))
        
        var inviter: InviterDetails?
        if let roomMemberProxy = details.inviter {
            inviter = .init(userID: roomMemberProxy.userID,
                            displayName: roomMemberProxy.displayName,
                            avatarURL: roomMemberProxy.avatarURL)
        }
        
        self.init(id: identifier,
                  roomId: details.id,
                  type: details.isInvite ? .invite : .room,
                  badges: .init(isDotShown: isDotShown,
                                isMentionShown: isMentionShown,
                                isMuteShown: isMuteShown,
                                isCallShown: isCallShown),
                  name: details.name,
                  isDirect: details.isDirect,
                  isHighlighted: isHighlighted,
                  isFavourite: details.isFavourite,
                  timestamp: details.lastMessageFormattedTimestamp,
                  lastMessage: details.lastMessage,
                  avatarURL: details.avatarURL,
                  inviter: inviter,
                  canonicalAlias: details.canonicalAlias)
    }
}
