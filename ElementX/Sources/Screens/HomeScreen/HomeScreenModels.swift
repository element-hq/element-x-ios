//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    case presentGlobalSearch
    case presentRoomDirectorySearch
    case logoutWithoutConfirmation
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
    case confirmSlidingSyncUpgrade
    case skipSlidingSyncUpgrade
    case updateVisibleItemRange(Range<Int>)
    case globalSearch
    case markRoomAsUnread(roomIdentifier: String)
    case markRoomAsRead(roomIdentifier: String)
    case markRoomAsFavourite(roomIdentifier: String, isFavourite: Bool)
    case selectRoomDirectorySearch
    
    case acceptInvite(roomIdentifier: String)
    case declineInvite(roomIdentifier: String)
}

enum HomeScreenRoomListMode: CustomStringConvertible {
    case skeletons
    case empty
    case rooms
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .rooms:
            return "Showing rooms"
        }
    }
}

enum HomeScreenBannerMode {
    case none
    case dismissed
    case show
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var securityBannerMode = HomeScreenBannerMode.none
    var slidingSyncMigrationBannerMode = HomeScreenBannerMode.none
    
    var requiresExtraAccountSetup = false
        
    var rooms: [HomeScreenRoom] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    var hasPendingInvitations = false
    
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
    
    var shouldShowFilters: Bool {
        !bindings.isSearchFieldFocused && roomListMode == .rooms
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
    
    static let placeholderLastMessage = AttributedString("Hidden last message")
        
    /// The list item identifier is it's room identifier.
    let id: String
    
    /// The real room identifier this item points to
    let roomID: String?
    
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
    
    let avatar: RoomAvatar
    
    let inviter: RoomInviterDetails?
    
    let canonicalAlias: String?
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomID: nil,
                       type: .placeholder,
                       badges: .init(isDotShown: false, isMentionShown: false, isMuteShown: false, isCallShown: false),
                       name: "Placeholder room name",
                       isDirect: false,
                       isHighlighted: false,
                       isFavourite: false,
                       timestamp: "Now",
                       lastMessage: placeholderLastMessage,
                       avatar: .room(id: "", name: "", avatarURL: nil),
                       inviter: nil,
                       canonicalAlias: nil)
    }
}

extension HomeScreenRoom {
    init(summary: RoomSummary, hideUnreadMessagesBadge: Bool) {
        let identifier = summary.id
        
        let hasUnreadMessages = hideUnreadMessagesBadge ? false : summary.hasUnreadMessages
        
        let isDotShown = hasUnreadMessages || summary.hasUnreadMentions || summary.hasUnreadNotifications || summary.isMarkedUnread
        let isMentionShown = summary.hasUnreadMentions && !summary.isMuted
        let isMuteShown = summary.isMuted
        let isCallShown = summary.hasOngoingCall
        let isHighlighted = summary.isMarkedUnread || (!summary.isMuted && (summary.hasUnreadNotifications || summary.hasUnreadMentions))
        
        let inviter = summary.inviter.map(RoomInviterDetails.init)
        
        self.init(id: identifier,
                  roomID: summary.id,
                  type: summary.isInvite ? .invite : .room,
                  badges: .init(isDotShown: isDotShown,
                                isMentionShown: isMentionShown,
                                isMuteShown: isMuteShown,
                                isCallShown: isCallShown),
                  name: summary.name,
                  isDirect: summary.isDirect,
                  isHighlighted: isHighlighted,
                  isFavourite: summary.isFavourite,
                  timestamp: summary.lastMessageFormattedTimestamp,
                  lastMessage: summary.lastMessage,
                  avatar: summary.avatar,
                  inviter: inviter,
                  canonicalAlias: summary.canonicalAlias)
    }
}
