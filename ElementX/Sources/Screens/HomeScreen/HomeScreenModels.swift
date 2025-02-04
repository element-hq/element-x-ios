//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit
import SwiftUI

enum HomeScreenViewModelAction {
    case presentRoom(roomIdentifier: String)
    case presentRoomDetails(roomIdentifier: String)
    case roomLeft(roomIdentifier: String)
    case presentSecureBackupSettings
    case presentRecoveryKeyScreen
    case presentEncryptionResetScreen
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
    case setupRecovery
    case confirmRecoveryKey
    case resetEncryption
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
    
    case loadRewards
    case rewardsIntimated
    
    case loadMorePostsIfNeeded
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

enum HomeScreenPostListMode: CustomStringConvertible {
    case skeletons
    case empty
    case posts
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .posts:
            return "Showing posts"
        }
    }
}

enum HomeScreenSecurityBannerMode: Equatable {
    case none
    case dismissed
    case show(HomeScreenRecoveryKeyConfirmationBanner.State)
    
    var isDismissed: Bool {
        switch self {
        case .dismissed: true
        default: false
        }
    }
    
    var isShown: Bool {
        switch self {
        case .show: true
        default: false
        }
    }
}

enum HomeScreenMigrationBannerMode {
    case none, show, dismissed
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    var primaryZeroId: String?
    
    var securityBannerMode = HomeScreenSecurityBannerMode.none
    var slidingSyncMigrationBannerMode = HomeScreenMigrationBannerMode.none
    
    var requiresExtraAccountSetup = false
        
    var rooms: [HomeScreenRoom] = []
    var posts: [HomeScreenPost] = []
    var roomListMode: HomeScreenRoomListMode = .skeletons
    var postListMode: HomeScreenPostListMode = .skeletons
    
    var canLoadMorePosts: Bool = true
    
    var hasPendingInvitations = false
    
    var isRoomDirectorySearchEnabled = false
    
    var selectedRoomID: String?
    
    var visibleRooms: [HomeScreenRoom] {
        if roomListMode == .skeletons {
            return placeholderRooms
        }
        
        return rooms
    }
    
    var visiblePosts: [HomeScreenPost] {
        if postListMode == .skeletons {
            return placeholderPosts
        }
        
        return posts
    }
    
    var userRewards = ZeroRewards.empty()
    var showNewUserRewardsIntimation = false
    
    var bindings = HomeScreenViewStateBindings()
    
    var placeholderRooms: [HomeScreenRoom] {
        (1...10).map { _ in
            HomeScreenRoom.placeholder()
        }
    }
    
    var placeholderPosts: [HomeScreenPost] {
        (1...10).map { _ in
            HomeScreenPost.placeholder()
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
    enum RoomType: Equatable {
        case placeholder
        case room
        case invite(inviterDetails: RoomInviterDetails?)
        case knock
    }
    
    static let placeholderLastMessage = AttributedString("Hidden last message")
        
    /// The list item identifier is it's room identifier.
    let id: String
    
    /// The real room identifier this item points to
    let roomID: String?
    
    let type: RoomType
    
    var inviter: RoomInviterDetails? {
        if case .invite(let inviter) = type {
            return inviter
        }
        return nil
    }
    
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
                       canonicalAlias: nil)
    }
}

struct HomeScreenPost: Identifiable, Equatable {
    let id: String
    
    // sender info
    let senderInfo: UserProfileProxy
    let senderPrimaryZId: String?
    
    // post info
    let postText: String?
    let attributedPostText: AttributedString?
    let postUpdatedAt: String
    let postCreatedAt: String
    let postTimestamp: String
    
    let postImageURL: URL?
    
    let worldPrimaryZId: String?
    let meowCount: String
    let repliesCount: String
    
    static func placeholder() -> HomeScreenPost {
        HomeScreenPost(id: UUID().uuidString,
                       senderInfo: UserProfileProxy(userID: UUID().uuidString),
                       senderPrimaryZId: "0://placeholder-sender-zid",
                       postText: "Placeholder post text...",
                       attributedPostText: AttributedString("Placeholder post text..."),
                       postUpdatedAt: "",
                       postCreatedAt: "",
                       postTimestamp: "Now",
                       postImageURL: nil,
                       worldPrimaryZId: "0://placeholder-world-zid",
                       meowCount: "0",
                       repliesCount: "0")
    }
}

extension HomeScreenRoom {
    init(summary: RoomSummary, hideUnreadMessagesBadge: Bool) {
        let identifier = summary.id
        
        let hasUnreadMessages = hideUnreadMessagesBadge ? false : summary.hasUnreadMessages
        
        let isDotShown = hasUnreadMessages || summary.hasUnreadMentions || summary.hasUnreadNotifications || summary.isMarkedUnread || summary.knockRequestType?.isKnock == true
        let isMentionShown = summary.hasUnreadMentions && !summary.isMuted
        let isMuteShown = summary.isMuted
        let isCallShown = summary.hasOngoingCall
        let isHighlighted = summary.isMarkedUnread || (!summary.isMuted && (summary.hasUnreadNotifications || summary.hasUnreadMentions)) || summary.knockRequestType?.isKnock == true
        
        let type: HomeScreenRoom.RoomType = switch summary.knockRequestType {
        case .invite(let inviter): .invite(inviterDetails: inviter.map(RoomInviterDetails.init))
        case .knock: .knock
        case .none: .room
        }
        
        self.init(id: identifier,
                  roomID: summary.id,
                  type: type,
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
                  canonicalAlias: summary.canonicalAlias)
    }
}

extension HomeScreenPost {
    init(post: ZPost, rewardsDecimalPlaces: Int = 0) {
        let userProfile = post.user.profileSummary
        let meowCount = post.postsMeowsSummary?.meowCount(decimal: rewardsDecimalPlaces) ?? "0"
        let postUpdatedAt = DateUtil.shared.dateFromISO8601String(post.updatedAt)
        let postTimeStamp = postUpdatedAt.formattedMinimal()
        let repliesCount = String(post.replies?.count ?? 0)
        
        let attributedString = post.text.isEmpty ? nil : HomeScreenPost.attributedString(from: post.text)
        
        self.init(
            id: post.id.rawValue,
            senderInfo: UserProfileProxy(userID: userProfile.id,
                                         displayName: userProfile.fullName,
                                         avatarURL: URL(string: userProfile.profileImage)),
            senderPrimaryZId: post.zid,
            postText: post.text,
            attributedPostText: attributedString,
            postUpdatedAt: post.updatedAt,
            postCreatedAt: post.createdAt,
            postTimestamp: postTimeStamp,
            postImageURL: (post.imageUrl != nil) ? URL(string: post.imageUrl!) : nil,
            worldPrimaryZId: post.worldZid,
            meowCount: meowCount,
            repliesCount: repliesCount
        )
    }
    
    private static func attributedString(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        let patterns: [(String, Color, Bool)] = [
            ("#\\w+", Asset.Colors.blue11.swiftUIColor, false),  // Hashtags
            ("@\\w+", Asset.Colors.blue11.swiftUIColor, false),  // Mentions
            ("(https?://\\S+|www\\.\\S+)", Asset.Colors.blue11.swiftUIColor, true) // URLs
        ]
        
        for (pattern, color, isLink) in patterns {
            applyAttributes(&attributedString, pattern: pattern, color: color, isLink: isLink)
        }
        
        return attributedString
    }
    
    private static func applyAttributes(_ attributedString: inout AttributedString,
                                        pattern: String,
                                        color: Color,
                                        isLink: Bool = false) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let fullText = String(attributedString.characters)
        let matches = regex.matches(in: fullText, range: NSRange(location: 0, length: fullText.utf16.count))
        
        for match in matches.reversed() {  // Reverse order to avoid index shifting issues
            guard let range = Range(match.range, in: attributedString) else { continue }
            
            attributedString[range].foregroundColor = color
            
            if isLink {
                let linkText = String(attributedString[range].characters)
                let urlString = linkText.hasPrefix("www.") ? "https://\(linkText)" : linkText
                if let url = URL(string: urlString) {
                    attributedString[range].link = url
                    attributedString[range].underlineStyle = .single
                }
            }
        }
    }
}
