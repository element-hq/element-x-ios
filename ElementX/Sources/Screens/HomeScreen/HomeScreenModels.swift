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
    case presentReportRoom(roomIdentifier: String)
    case presentDeclineAndBlock(userID: String, roomID: String)
    case roomLeft(roomIdentifier: String)
    case transferOwnership(roomIdentifier: String)
    case presentSecureBackupSettings
    case presentRecoveryKeyScreen
    case presentEncryptionResetScreen
    case presentSettingsScreen(userRewardsProtocol: UserRewardsProtocol)
    case presentFeedbackScreen
    case presentStartChatScreen
    case presentCreateFeedScreen(feedProtocol: FeedProtocol)
    case presentGlobalSearch
    case logout
    case postTapped(_ post: HomeScreenPost, feedProtocol: FeedProtocol)
    case openPostUserProfile(_ profile: ZPostUserProfile, feedProtocol: FeedProtocol)
    case startWalletTransaction(WalletTransactionProtocol, WalletTransactionType, ZeroCurrency?)
}

enum HomeScreenViewAction {
    case onHomeTabChanged
    
    case selectRoom(roomIdentifier: String)
    case showRoomDetails(roomIdentifier: String)
    case leaveRoom(roomIdentifier: String)
    case confirmLeaveRoom(roomIdentifier: String)
    case reportRoom(roomIdentifier: String)
    case showSettings
    case startChat
    case newFeed
    case setupRecovery
    case confirmRecoveryKey
    case resetEncryption
    case skipRecoveryKeyConfirmation
    case updateVisibleItemRange(Range<Int>)
    case globalSearch
    case markRoomAsUnread(roomIdentifier: String)
    case markRoomAsRead(roomIdentifier: String)
    case markRoomAsFavourite(roomIdentifier: String, isFavourite: Bool)
    
    case acceptInvite(roomIdentifier: String)
    case declineInvite(roomIdentifier: String)
    
    case loadRewards
    case rewardsIntimated
    
    case loadMoreAllPosts(followingPostsOnly: Bool)
    case loadMoreMyPosts
    case forceRefreshAllPosts(followingPostsOnly: Bool)
    case forceRefreshMyPosts
    case addMeowToPost(postId: String, amount: Int)
    
    case postTapped(_ post: HomeScreenPost)
    case openArweaveLink(_ post: HomeScreenPost)
    case openYoutubeLink(_ url: String)
    case openPostUserProfile(_ profile: ZPostUserProfile)
    case openUserProfile
    case openMediaPreview(_ mediaId: String, key: String)
    case reloadFeedMedia(_ post: HomeScreenPost)
    
    case forceRefreshChannels
    case channelTapped(_ channel: HomeScreenChannel)
    case setNotificationFilter(_ tab: HomeNotificationsTab)
    
    case toggleWalletBalance(show: Bool)
    case loadMoreWalletTokens
    case loadMoreWalletTransactions
    case loadMoreWalletNFTs
    case startWalletTransaction(WalletTransactionType)
    case viewTransactionDetails(transactionId: String)
    case claimRewards(trigger: Bool)
    
    case onStakePoolSelected(HomeScreenWalletStakingContent)
    case claimStakeRewards
    case stakeAmount(String)
    case unstakeAmount(String)
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

enum HomeScreenChannelListMode: CustomStringConvertible {
    case skeletons
    case empty
    case channels
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .channels:
            return "Showing channels"
        }
    }
}

enum HomeScreenWalletContentListMode: CustomStringConvertible {
    case skeletons
    case content
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .content:
            return "Showing wallet content"
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

enum ClaimRewardsState {
    case none
    case claiming
    case success(String)
    case failure
}

enum StakePoolViewState {
    case details
    case staking
    case unstaking
    case inProgress
    case success
    case failure
}

struct HomeScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var currentUserZeroProfile: ZCurrentUser?
    
    var securityBannerMode = HomeScreenSecurityBannerMode.none
    
    var requiresExtraAccountSetup = false
    
    var rooms: [HomeScreenRoom] = []
    var directRoomsUserStatusMap: [String : Bool] = [:]
    var posts: [HomeScreenPost] = []
    var myPosts: [HomeScreenPost] = []
    var channels: [HomeScreenChannel] = []
    var walletTokens: [HomeScreenWalletContent] = []
    var walletTransactions: [HomeScreenWalletContent] = []
    var walletNFTs: [HomeScreenWalletContent] = []
    var walletStakings: [HomeScreenWalletStakingContent] = []
    
    var walletTokenNextPageParams: NextPageParams? = nil
    var walletNFTsNextPageParams: NextPageParams? = nil
    var walletTransactionsNextPageParams: TransactionNextPageParams? = nil
    
    var meowPrice: ZeroCurrency? = nil
    
    var roomListMode: HomeScreenRoomListMode = .skeletons
    var postListMode: HomeScreenPostListMode = .skeletons
    var myPostListMode: HomeScreenPostListMode = .skeletons
    var channelsListMode: HomeScreenChannelListMode = .skeletons
    var walletContentListMode: HomeScreenWalletContentListMode = .skeletons
    
    var canLoadMorePosts: Bool = true
    var canLoadMoreMyPosts: Bool = true
    
    var hasPendingInvitations = false
    
    var selectedRoomID: String?
    
    var hideInviteAvatars = false
    
    var reportRoomEnabled = false
    
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
    var visibleMyPosts: [HomeScreenPost] {
        if myPostListMode == .skeletons {
            return placeholderPosts
        }
        
        return myPosts
    }
    var visibleChannels: [HomeScreenChannel] {
        if channelsListMode == .skeletons {
            return placeholderChannels
        }
        
        return channels
    }
    var visibleWalletTokens: [HomeScreenWalletContent] {
        if walletContentListMode == .skeletons {
            return placeholderWalletContent
        }
        return walletTokens
    }
    var visibleWalletTransactions: [HomeScreenWalletContent] {
        if walletContentListMode == .skeletons {
            return placeholderWalletContent
        }
        return walletTransactions
    }
    var visibleWalletNFTs: [HomeScreenWalletContent] {
        if walletContentListMode == .skeletons {
            return placeholderWalletContent
        }
        return walletNFTs
    }
    var visibleWalletStakings: [HomeScreenWalletStakingContent] {
        if walletContentListMode == .skeletons {
            return (1...20).map { _ in
                HomeScreenWalletStakingContent.placeholder()
            }
        }
        return walletStakings
    }
    
    var userRewards = ZeroRewards.empty()
    var claimableUserRewards = ZeroRewards.empty()
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
    var placeholderChannels: [HomeScreenChannel] {
        (1...20).map { index in
            HomeScreenChannel.placeholder(index)
        }
    }
    var placeholderWalletContent: [HomeScreenWalletContent] {
        (1...20).map { _ in
            HomeScreenWalletContent.placeholder()
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
    
    var postLinkPreviewsMap: [String: ZLinkPreview] = [:]
    var postMediaInfoMap: [String: HomeScreenPostMediaInfo] = [:]
    
    var notificationsContent: [HomeScreenRoom] = []
    var hasNewNotificatios: Bool {
        let allNotificationContent = visibleRooms.filter {
            switch $0.type {
            case .placeholder, .knock:
                return false
            default:
                return $0.badges.isDotShown
            }
        }
        return !allNotificationContent.isEmpty
    }
        
    var claimRewardsState: ClaimRewardsState = .none
    
    var walletBalance: Double = 0
    var showWalletBalance: Bool = true
    var userWalletBalance: String {
        showWalletBalance ? "$\(walletBalance.formatToThousandSeparatedString())" : "*****"
    }
    
    var selectedStakePool: SelectedHomeWalletStakePool?
}

struct HomeScreenViewStateBindings {
    var filtersState = RoomListFiltersState()
    var searchQuery = ""
    var isSearchFieldFocused = false
    
    var alertInfo: AlertInfo<UUID>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: URL?
    
    var showEarningsClaimedSheet: Bool = false
    var showStakePoolSheet: Bool = false
    
    var stakePoolViewState: StakePoolViewState = .details
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
    
    var badges: Badges
    struct Badges: Equatable {
        let isDotShown: Bool
        let isMentionShown: Bool
        var isMuteShown: Bool
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
    
    let isTombstoned: Bool
    
    var displayedLastMessage: AttributedString? {
        // If the room is tombstoned, show a specific message, regardless of any last message.
        guard !isTombstoned else {
            return AttributedString(L10n.screenRoomlistTombstonedRoomDescription)
        }
        return lastMessage
    }
    
    let unreadNotificationsCount: UInt
    
    var isAChannel: Bool {
        name.starts(with: ZeroContants.ZERO_CHANNEL_PREFIX)
    }
    
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
                       canonicalAlias: nil,
                       isTombstoned: false,
                       unreadNotificationsCount: 0)
    }
}

struct HomeScreenPost: Identifiable, Equatable {
    let id: String
    
    // sender info
    let senderInfo: UserProfileProxy
    let senderPrimaryZId: String?
    
    // post info
    let postText: String?
    let attributedSenderHeaderText: AttributedString
    let attributedPostText: AttributedString?
    let postUpdatedAt: String
    let postCreatedAt: String
    let postTimestamp: String
    
    let postImageURL: URL?
    
    let worldPrimaryZId: String?
    let meowCount: String
    let repliesCount: String
    
    let isPostInOwnFeed: Bool
    let arweaveId: String
    let isMeowedByMe: Bool
    let postDateTime: String
    let isMyPost: Bool
    
    let senderProfile: ZPostUserProfile?
    
    var mediaInfo: HomeScreenPostMediaInfo?
    var urlLinkPreview: ZLinkPreview?
    
    static func placeholder() -> HomeScreenPost {
        HomeScreenPost(id: UUID().uuidString,
                       senderInfo: UserProfileProxy(userID: UUID().uuidString),
                       senderPrimaryZId: "0://placeholder-sender-zid",
                       postText: "Placeholder post text...",
                       attributedSenderHeaderText: AttributedString("Placeholder sender text..."),
                       attributedPostText: AttributedString("Placeholder post text..."),
                       postUpdatedAt: "",
                       postCreatedAt: "",
                       postTimestamp: "Now",
                       postImageURL: nil,
                       worldPrimaryZId: "0://placeholder-world-zid",
                       meowCount: "0",
                       repliesCount: "0",
                       isPostInOwnFeed: false,
                       arweaveId: "",
                       isMeowedByMe: false,
                       postDateTime: "",
                       isMyPost: false,
                       senderProfile: nil,
                       mediaInfo: nil,
                       urlLinkPreview: nil)
    }
}

struct HomeScreenPostMediaInfo: Identifiable, Equatable {
    let id: String
    let mimeType: String?
    let aspectRatio: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    var url: String?
}

struct HomeScreenChannel: Identifiable, Equatable {
    let id: String
    let channelFullName: String
    let displayName: String
    
    var notificationsCount: UInt = 0
    
    static func placeholder(_ index: Int) -> HomeScreenChannel {
        .init(id: UUID().uuidString,
              channelFullName: "0://placeholderChannel\(index).name",
              displayName: "0://placeholderChannel\(index)")
    }
}

struct HomeScreenWalletContent: Identifiable, Equatable {
    let id: String
    let icon: String?
    let header: String?
    
    let transactionAction: String?
    let transactionAddress: String?
    let title: String
    let description: String?
    
    let actionPreText: String?
    let actionText: String
    let actionPostText: String?
    
    static func placeholder() -> HomeScreenWalletContent {
        .init(id: UUID().uuidString,
              icon: nil,
              header: nil,
              transactionAction: nil,
              transactionAddress: nil,
              title: "placeholder title",
              description: "placeholder description",
              actionPreText: nil,
              actionText: "placeholder action text",
              actionPostText: "placeholder action post text")
    }
}

struct HomeScreenWalletStakingContent: Identifiable, Equatable {
    let id: String
    let userWalletAddress: String
    
    let poolAddress: String
    let poolIcon: String?
    let poolName: String
    
    let tokenAddress: String
    let tokenAmount: String
    let tokenIcon: String?
    
    let totalStakedAmount: Double
    let totalStakedAmountFormatted: String
    let myStakeAmount: Double
    let myStateAmountFormatted: String
    
    static func placeholder() -> HomeScreenWalletStakingContent {
        .init(id: UUID().uuidString,
              userWalletAddress: "",
              poolAddress: "",
              poolIcon: nil,
              poolName: "placeholder pool",
              tokenAddress: "",
              tokenAmount: "",
              tokenIcon: nil,
              totalStakedAmount: 0,
              totalStakedAmountFormatted: "",
              myStakeAmount: 0,
              myStateAmountFormatted: "")
    }
    
}

struct SelectedHomeWalletStakePool {
    let pool: HomeScreenWalletStakingContent
    let stakeToken: ZWalletTokenInfo?
    let stakeTokenBalance: ZWalletTokenBalance?
    let rewardToken: ZWalletTokenInfo?
    let rewardTokenBalance: ZWalletTokenBalance?
}

extension SelectedHomeWalletStakePool {
    var claimableRewardValue: String {
        ZeroRewards.parseCredits(credits: rewardTokenBalance?.balance ?? "0", decimals: rewardToken?.decimals ?? 18)
            .formatToSuffix()
    }
    
    var myStakedTokens: Double {
        ZeroRewards.parseCredits(credits: pool.tokenAmount, decimals: stakeToken?.decimals ?? 18)
    }
    
    var myStakedTokensFormatted: String {
        myStakedTokens.formatToSuffix()
    }
    
    var totalAvailableTokenBalance: Double {
        ZeroRewards.parseCredits(credits: stakeTokenBalance?.balance ?? "0", decimals: stakeToken?.decimals ?? 18)
    }
    
    var totalAvailableTokenBalanceFormatted: String {
        totalAvailableTokenBalance.formatToSuffix()
    }
}

extension HomeScreenRoom {
    init(summary: RoomSummary, hideUnreadMessagesBadge: Bool, seenInvites: Set<String> = []) {
        let roomID = summary.id
        
        let hasUnreadMessages = hideUnreadMessagesBadge ? false : summary.hasUnreadMessages
        let isUnseenInvite = summary.joinRequestType?.isInvite == true && !seenInvites.contains(roomID)
        
        let isDotShown = hasUnreadMessages || summary.hasUnreadMentions || summary.hasUnreadNotifications || summary.isMarkedUnread || isUnseenInvite
        let isMentionShown = summary.hasUnreadMentions && !summary.isMuted
        let isMuteShown = summary.isMuted
        let isCallShown = summary.hasOngoingCall
        let isHighlighted = summary.isMarkedUnread || (!summary.isMuted && (summary.hasUnreadNotifications || summary.hasUnreadMentions)) || isUnseenInvite
        
        let type: HomeScreenRoom.RoomType = switch summary.joinRequestType {
        case .invite(let inviter): .invite(inviterDetails: inviter.map(RoomInviterDetails.init))
        case .knock: .knock
        case .none: .room
        }
        
        self.init(id: roomID,
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
                  timestamp: summary.lastMessageDate?.formattedMinimal(),
                  lastMessage: summary.lastMessage,
                  avatar: summary.avatar,
                  canonicalAlias: summary.canonicalAlias,
                  isTombstoned: summary.isTombstoned,
                  unreadNotificationsCount: summary.unreadMessagesCount // settings to unread messages count to show new messages count only
        )
    }
}

extension HomeScreenPost {
    init(loggedInUserId: String, post: ZPost, rewardsDecimalPlaces: Int = 0) {
        let userProfile = post.user.profileSummary
        let meowCount = post.postsMeowsSummary?.meowCount(decimal: rewardsDecimalPlaces) ?? "0"
        let postUpdatedAt = DateUtil.shared.dateFromISO8601String(post.updatedAt)
        let postTimeStamp = postUpdatedAt.timeAgo()
        let repliesCount = String(post.replies?.count ?? 0)
        
        let attributedSenderHeaderText = HomeScreenPost.attributedSenderHeader(from: userProfile.fullName,
                                                                               timeStamp: postTimeStamp)
        let attributedPostText = post.text.isEmpty ? nil : HomeScreenPost.attributedPostText(from: post.text)
        let isPostInOwnFeed = post.worldZid == post.zid
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm aa • MMM d, yyyy"
        let postDateTime = formatter.string(from: postUpdatedAt)
        
        let isMyPost = loggedInUserId.matrixIdToCleanHex() == post.userId.matrixIdToCleanHex()
        let mediaInfo: HomeScreenPostMediaInfo? = (post.media == nil) ? nil : .init(id: post.media!.id,
                                                                                    mimeType: post.media!.mimeType,
                                                                                    aspectRatio: post.media!.width / post.media!.height,
                                                                                    width: post.media!.width,
                                                                                    height: post.media!.height,
                                                                                    url: nil)
        
        self.init(
            id: post.id.rawValue,
            senderInfo: UserProfileProxy(userID: userProfile.id,
                                         displayName: userProfile.fullName,
                                         avatarURL: URL(string: userProfile.profileImage ?? "")),
            senderPrimaryZId: post.zid,
            postText: post.text,
            attributedSenderHeaderText: attributedSenderHeaderText,
            attributedPostText: attributedPostText,
            postUpdatedAt: postTimeStamp,
            postCreatedAt: post.createdAt,
            postTimestamp: postTimeStamp,
            postImageURL: (post.imageUrl != nil) ? URL(string: post.imageUrl!) : nil,
            worldPrimaryZId: post.worldZid,
            meowCount: meowCount,
            repliesCount: repliesCount,
            isPostInOwnFeed: isPostInOwnFeed,
            arweaveId: post.arweaveId,
            isMeowedByMe: (post.meows?.isEmpty == false),
            postDateTime: postDateTime,
            isMyPost: isMyPost,
            senderProfile: post.userProfileView,
            mediaInfo: mediaInfo
        )
    }
    
    func withUpdatedData(mediaInfo: HomeScreenPostMediaInfo?, urlLinkPreview: ZLinkPreview?) -> Self {
        var updatedSelf = self
        updatedSelf.mediaInfo = mediaInfo
        updatedSelf.urlLinkPreview = urlLinkPreview
        return updatedSelf
    }
    
    func withUpdatedData(url: String?, urlLinkPreview: ZLinkPreview?) -> Self {
        var updatedSelf = self
        updatedSelf.mediaInfo?.url = url
        updatedSelf.urlLinkPreview = urlLinkPreview
        return updatedSelf
    }
    
    func getArweaveLink() -> URL? {
        let arweaveHost = "https://of2ub4a2ai55lgpqj5z7so7j7v6uwjcruh6cdm3ojgnhqngahkwa.arweave.net/"
        let arweaveUrl = arweaveHost.appending(arweaveId)
        return URL(string: arweaveUrl)
    }
    
    private static func attributedPostText(from text: String) -> AttributedString {
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
    
    
    private static func attributedSenderHeader(from senderName: String, timeStamp: String) -> AttributedString {
        let timeStampPostFix = " • \(timeStamp)"
        var attributedSenderHeader = AttributedString("\(senderName)\(timeStampPostFix)")
        // applyAttributes
        let nameRange = attributedSenderHeader.range(of: senderName)!
        let timeStampRange = attributedSenderHeader.range(of: timeStampPostFix)!
        attributedSenderHeader[nameRange].foregroundColor = .compound.textPrimary
        attributedSenderHeader[timeStampRange].foregroundColor = .compound.textSecondary
        attributedSenderHeader[nameRange].font = .compound.bodyMDSemibold
        attributedSenderHeader[timeStampRange].font = .zero.bodyMD
        
        return attributedSenderHeader
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

extension HomeScreenChannel {
    init(channelZId: String) {
        let channelDisplayName = String((channelZId.split(separator: ".").first ?? ""))
        let rootChannelName = channelDisplayName.replacingOccurrences(of: ZeroContants.ZERO_CHANNEL_PREFIX, with: "")
        let channelId = "#\(rootChannelName):\(ZeroContants.appServer.matrixHomeServerPostfix)"
        
        self.init(
            id: channelId,
            channelFullName: channelZId,
            displayName: channelDisplayName
        )
    }
}

extension HomeScreenPostMediaInfo {
    init (media: ZPostMedia) {
        let mediaInfo = media.media
        self.init(id: mediaInfo.id,
                  mimeType: mediaInfo.mimeType,
                  aspectRatio: mediaInfo.width / mediaInfo.height,
                  width: mediaInfo.width,
                  height: mediaInfo.height,
                  url: media.signedUrl)
    }
    
    var isVideo: Bool {
        return mimeType?.hasPrefix("video/") == true
    }
    
    func withUpdatedUrl(mediaUrl: URL) -> HomeScreenPostMediaInfo {
        return .init(id: self.id, mimeType: self.mimeType, aspectRatio: self.aspectRatio,
                     width: self.width, height: self.height, url: mediaUrl.absoluteString)
    }
}

extension HomeScreenWalletContent {
    init (walletToken: ZWalletToken, meowPrice: ZeroCurrency?) {
        let priceDifference: String? = if let diff = meowPrice?.diff {
            diff > 0 ? "+\(diff)%" : "-\(abs(diff))%"
        } else {
            nil
        }
        self.init(id: walletToken.tokenAddress,
                  icon: walletToken.logo,
                  header: nil,
                  transactionAction: nil,
                  transactionAddress: nil,
                  title: walletToken.name,
                  description: "\(walletToken.formattedAmount) \(walletToken.symbol.uppercased())",
                  actionPreText: nil,
                  actionText: walletToken.isClaimableToken ? "$\(walletToken.meowPriceFormatted(ref: meowPrice))" : "",
                  actionPostText: walletToken.isClaimableToken ? priceDifference : nil
        )
    }
    
    init(walletNFT: NFT) {
        self.init(id: walletNFT.id,
                  icon: walletNFT.imageUrl,
                  header: nil,
                  transactionAction: nil,
                  transactionAddress: nil,
                  title: walletNFT.collectionName ?? walletNFT.metadata.name ?? "",
                  description: nil,
                  actionPreText: nil,
                  actionText: "0",
                  actionPostText: nil)
    }
    
    init(walletTransaction: WalletTransaction, meowPrice: ZeroCurrency?) {
        let isTransactionReceived = walletTransaction.action.lowercased() == "receive"
        let tokenSymbol = walletTransaction.token.symbol.uppercased()
        self.init(id: walletTransaction.hash,
                  icon: walletTransaction.token.logo,
                  header: nil, //walletTransaction.timestamp
                  transactionAction: isTransactionReceived ? "Received from" : "Sent to",
                  transactionAddress: isTransactionReceived ? displayFormattedAddress(walletTransaction.from) : displayFormattedAddress( walletTransaction.to),
                  title: walletTransaction.token.name,
                  description: nil,
                  actionPreText: nil,
                  actionText: "\(walletTransaction.formattedAmount) \(tokenSymbol)",
                  actionPostText: walletTransaction.isClaimableTokenTransaction ? "$\(walletTransaction.meowPriceFormatted(ref: meowPrice))" : nil)
    }
}

extension HomeScreenWalletStakingContent {
    init(meowPrice: ZeroCurrency?, token: ZWalletToken, userWalletAddress: String,
         poolAddress: String, totalStaked: String, stakingConfig: ZStackingConfig,
         stakerStatus: ZStakingStatus, stakeRewards: ZStakingUserRewardsInfo) {
        let totalStakedAmount = ZeroWalletUtil.shared.meowPrice(tokenAmount: ZeroRewards.parseCredits(credits: totalStaked,
                                                                                                      decimals: 18),
                                                                refPrice: meowPrice)
        let myStakeAmount = ZeroWalletUtil.shared.meowPrice(tokenAmount: ZeroRewards.parseCredits(credits: stakerStatus.amountStaked,
                                                                                                  decimals: 18),
                                                            refPrice: meowPrice)
        self.init(id: poolAddress,
                  userWalletAddress: userWalletAddress,
                  poolAddress: poolAddress,
                  poolIcon: token.logo,
                  poolName: "\(token.name.uppercased()) Pool",
                  tokenAddress: token.tokenAddress,
                  tokenAmount: stakerStatus.amountStaked,
                  tokenIcon: token.logo,
                  totalStakedAmount: totalStakedAmount,
                  totalStakedAmountFormatted: "$\(totalStakedAmount.formatToSuffix())",
                  myStakeAmount: myStakeAmount,
                  myStateAmountFormatted: "$\(myStakeAmount.formatToSuffix())")
    }
}
