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
    case presentSessionVerificationScreen
    case presentSecureBackupSettings
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentStartChatScreen
    case presentInvitesScreen
    case presentGlobalSearch
    case logout
}

enum HomeScreenViewUserMenuAction {
    case settings
    case logout
}

enum HomeScreenViewAction {
    case selectRoom(roomIdentifier: String)
    case showRoomDetails(roomIdentifier: String)
    case leaveRoom(roomIdentifier: String)
    case confirmLeaveRoom(roomIdentifier: String)
    case userMenu(action: HomeScreenViewUserMenuAction)
    case startChat
    case verifySession
    case confirmRecoveryKey
    case skipSessionVerification
    case skipRecoveryKeyConfirmation
    case updateVisibleItemRange(range: Range<Int>, isScrolling: Bool)
    case selectInvites
    case globalSearch
    case markRoomAsUnread(roomIdentifier: String)
    case markRoomAsRead(roomIdentifier: String)
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

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var isSessionVerified: Bool?
    var hasSessionVerificationBannerBeenDismissed = false
    var showSessionVerificationBanner: Bool {
        guard let isSessionVerified else {
            return false
        }
        
        return !isSessionVerified && !hasSessionVerificationBannerBeenDismissed
    }
    
    var requiresSecureBackupSetup = false

    var needsRecoveryKeyConfirmation = false
    var hasRecoveryKeyConfirmationBannerBeenDismissed = false
    var showRecoveryKeyConfirmationBanner: Bool {
        guard let isSessionVerified else {
            return false
        }
        
        return isSessionVerified && needsRecoveryKeyConfirmation && !hasRecoveryKeyConfirmationBannerBeenDismissed
    }
    
    var rooms: [HomeScreenRoom] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    
    var shouldShowFilters = false
    var markAsUnreadEnabled = false
    
    var hasPendingInvitations = false
    var hasUnreadPendingInvitations = false
    
    var selectedRoomID: String?
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        return rooms
    }
    
    var filtersState = RoomListFiltersState()
    
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
}

struct HomeScreenViewStateBindings {
    var searchQuery = ""
    var isSearchFieldFocused = false
    
    var alertInfo: AlertInfo<UUID>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
}

struct HomeScreenRoom: Identifiable, Equatable {
    static let placeholderLastMessage = AttributedString("Hidden last message")
        
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    var name = ""
    
    var isMarkedUnread: Bool
    
    var hasUnreadMessages = false
    
    var hasUnreadMentions = false
    
    var hasUnreadNotifications = false
    
    var hasOngoingCall = false
    
    var timestamp: String?
    
    var lastMessage: AttributedString?
    
    var avatarURL: URL?
    
    var notificationMode: RoomNotificationModeProxy?
    
    var isPlaceholder = false
    
    var hasNewContent: Bool {
        hasUnreadMessages || hasUnreadMentions || hasUnreadNotifications || isMarkedUnread
    }
    
    static func placeholder() -> HomeScreenRoom {
        HomeScreenRoom(id: UUID().uuidString,
                       roomId: nil,
                       name: "Placeholder room name",
                       isMarkedUnread: false,
                       hasUnreadMessages: false,
                       hasUnreadMentions: false,
                       hasUnreadNotifications: false,
                       timestamp: "Now",
                       lastMessage: placeholderLastMessage,
                       isPlaceholder: true)
    }
}

enum RoomListFilter: Int, CaseIterable, Identifiable {
    var id: Int {
        rawValue
    }
    
    case people
    case rooms
    case unreads
    case favourites
    case lowPriority
    
    var localizedName: String {
        switch self {
        case .people:
            return L10n.screenRoomlistFilterPeople
        case .rooms:
            return L10n.screenRoomlistFilterRooms
        case .unreads:
            return L10n.screenRoomlistFilterUnreads
        case .favourites:
            return L10n.screenRoomlistFilterFavourites
        case .lowPriority:
            return L10n.screenRoomlistFilterLowPriority
        }
    }
    
    var complementaryFilter: RoomListFilter? {
        switch self {
        case .people:
            return .rooms
        case .rooms:
            return .people
        case .unreads:
            return nil
        case .favourites:
            return .lowPriority
        case .lowPriority:
            return .favourites
        }
    }
}

final class RoomListFiltersState: ObservableObject {
    @Published private var enabledFilters: Set<RoomListFilter>
    
    init(enabledFilters: Set<RoomListFilter> = []) {
        self.enabledFilters = enabledFilters
    }
    
    var sortedEnabledFilters: [RoomListFilter] {
        enabledFilters.sorted(by: { $0.rawValue < $1.rawValue })
    }
    
    var sortedAvailableFilters: [RoomListFilter] {
        var availableFilters = Set(RoomListFilter.allCases)
        for filter in enabledFilters {
            availableFilters.remove(filter)
            if let complementaryFilter = filter.complementaryFilter {
                availableFilters.remove(complementaryFilter)
            }
        }
        return availableFilters.sorted(by: { $0.rawValue < $1.rawValue })
    }
    
    var isFiltering: Bool {
        !enabledFilters.isEmpty
    }
    
    func set(_ filter: RoomListFilter, isEnabled: Bool) {
        if isEnabled {
            enabledFilters.insert(filter)
        } else {
            enabledFilters.remove(filter)
        }
    }
    
    func clearFilters() {
        enabledFilters.removeAll()
    }
    
    func isEnabled(_ filter: RoomListFilter) -> Bool {
        enabledFilters.contains(filter)
    }
}
