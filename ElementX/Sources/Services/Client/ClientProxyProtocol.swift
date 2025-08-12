//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum ClientProxyAction {
    case receivedSyncUpdate
    case receivedAuthError(isSoftLogout: Bool)
    case receivedDecryptionError(UnableToDecryptInfo)
    
    var isSyncUpdate: Bool {
        if case .receivedSyncUpdate = self {
            return true
        } else {
            return false
        }
    }
}

enum ClientProxyLoadingState {
    case loading
    case notLoading
}

enum ClientProxyError: Error {
    case sdkError(Error)
    case forbiddenAccess
    case zeroError(Error)
    
    case postsLimitReached
    
    case invalidMedia
    case invalidServerName
    case invalidResponse
    case failedUploadingMedia(ErrorKind)
    case roomPreviewIsPrivate
    case failedRetrievingUserIdentity
    case failedResolvingRoomAlias
    case roomNotInLocalStore
    case invalidInvite
    
    case failedCompletingUserProfile
}

enum SlidingSyncConstants {
    static let maximumVisibleRangeSize = 30
}

/// This struct represents the configuration that we are using to register the application through Pusher to Sygnal
/// using the Matrix Rust SDK, more info here:
/// https://github.com/matrix-org/sygnal
struct PusherConfiguration {
    let identifiers: PusherIdentifiers
    let kind: PusherKind
    let appDisplayName: String
    let deviceDisplayName: String
    let profileTag: String?
    let lang: String
}

enum SessionVerificationState {
    case unknown
    case verified
    case unverified
}

// The `Decodable` conformance is just for the purpose of migration
enum TimelineMediaVisibility: Decodable {
    case always
    case privateOnly
    case never
}

// sourcery: AutoMockable
protocol ClientProxyProtocol: AnyObject, MediaLoaderProtocol {
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> { get }
    
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> { get }
    
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> { get }
    
    var userID: String { get }

    var deviceID: String? { get }

    var homeserver: String { get }
    
    // TODO: This is a temporary value, in the future we should throw a migration error
    // when decoding a session that contains a sliding sync proxy URL instead of restoring it.
    var needsSlidingSyncMigration: Bool { get }
    var slidingSyncVersion: SlidingSyncVersion { get }
    
    var canDeactivateAccount: Bool { get }
    
    var userIDServerName: String? { get }
    
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> { get }

    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> { get }

    /// We delay fetching this until after the first sync. Nil until then
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> { get }
    
    var timelineMediaVisibilityPublisher: CurrentValuePublisher<TimelineMediaVisibility, Never> { get }
    
    var hideInviteAvatarsPublisher: CurrentValuePublisher<Bool, Never> { get }
    
    var pusherNotificationClientIdentifier: String? { get }
    
    var roomSummaryProvider: RoomSummaryProviderProtocol { get }
    
    /// Used for listing rooms that shouldn't be affected by the main `roomSummaryProvider` filtering
    /// But can still be filtered by queries, since this may be shared across multiple views, remember to reset
    /// The filtering state when you are done with it
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol { get }
    
    /// Used for listing rooms, can't be filtered nor its state observed
    var staticRoomSummaryProvider: StaticRoomSummaryProviderProtocol { get }
    
    var roomsToAwait: Set<String> { get set }
    
    var notificationSettings: NotificationSettingsProxyProtocol { get }
    
    var secureBackupController: SecureBackupControllerProtocol { get }
    
    var sessionVerificationController: SessionVerificationControllerProxyProtocol? { get }
    
    var isReportRoomSupported: Bool { get async }
    
    var isLiveKitRTCSupported: Bool { get async }
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError>
    
    func startSync()

    func stopSync()
    
    func stopSync(completion: (() -> Void)?) // Hopefully this will become async once we get SE-0371.
        
    func accountURL(action: AccountManagementAction) async -> URL?
    
    func directRoomForUserID(_ userID: String) -> Result<String?, ClientProxyError>
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError>
    
    func createRoom(name: String,
                    topic: String?,
                    isRoomPrivate: Bool,
                    isKnockingOnly: Bool,
                    userIDs: [String],
                    avatarURL: URL?,
                    aliasLocalPart: String?) async -> Result<String, ClientProxyError>
    
    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError>
    
    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError>
    
    func knockRoom(_ roomID: String, via: [String], message: String?) async -> Result<Void, ClientProxyError>
    
    func knockRoomAlias(_ roomAlias: String, message: String?) async -> Result<Void, ClientProxyError>
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError>
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyType?
    
    func leaveRoom(_ roomID: String) async -> Result<Void, ClientProxyError>
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError>
    
    func roomSummaryForIdentifier(_ identifier: String) -> RoomSummary?
    
    func roomSummaryForAlias(_ alias: String) -> RoomSummary?
    
    /// Will only work for rooms that are in our room list/local store
    func reportRoomForIdentifier(_ identifier: String, reason: String) async -> Result<Void, ClientProxyError>
    
    func roomInfoForAlias(_ alias: String) async -> RoomInfoProxy?
    
    @discardableResult func loadUserDisplayName() async -> Result<Void, ClientProxyError>
    
    func setUserInfo(_ name: String, primaryZId: String?) async -> Result<Void, ClientProxyError>

    @discardableResult func loadUserAvatarURL() async -> Result<Void, ClientProxyError>
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError>
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError>

    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError>
    
    func logout() async

    func setPusher(with configuration: PusherConfiguration) async throws
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError>
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError>
    
    func isAliasAvailable(_ alias: String) async -> Result<Bool, ClientProxyError>
    
    @discardableResult func clearCaches() async -> Result<Void, ClientProxyError>
    
    func fetchMediaPreviewConfiguration() async -> Result<MediaPreviewConfig?, ClientProxyError>

    // MARK: - Ignored users
    
    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    // MARK: - Recently visited rooms
    
    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError>
    
    func recentlyVisitedRooms() async -> Result<[String], ClientProxyError>
    
    func recentConversationCounterparts() async -> [UserProfileProxy]
    
    // MARK: - Crypto
    
    func ed25519Base64() async -> String?
    func curve25519Base64() async -> String?
    
    func pinUserIdentity(_ userID: String) async -> Result<Void, ClientProxyError>
    func withdrawUserIdentityVerification(_ userID: String) async -> Result<Void, ClientProxyError>
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError>
    
    func userIdentity(for userID: String) async -> Result<UserIdentityProxyProtocol?, ClientProxyError>
    
    // MARK: - Moderation & Safety
    
    func setTimelineMediaVisibility(_ value: TimelineMediaVisibility) async -> Result<Void, ClientProxyError>
    func setHideInviteAvatars(_ value: Bool) async -> Result<Void, ClientProxyError>
    
    func verifyUserPassword(_ password: String) async -> Result<Void, ClientProxyError>
    
    func setRoomNotificationModeProtocol(_ listener: RoomNotificationModeUpdatedProtocol)
    
    func roomNotificationModeUpdated(roomId: String, notificationMode: RoomNotificationModeProxy)
    
    // MARK: - ZERO REWARDS
    
    var userRewardsPublisher: CurrentValuePublisher<ZeroRewards, Never> { get }
    var showNewUserRewardsIntimationPublisher: CurrentValuePublisher<Bool, Never> { get }
    
    func getUserRewards(shouldCheckRewardsIntiamtion: Bool) async -> Result<Void, ClientProxyError>
    
    func getZeroMeowPrice() async -> Result<ZeroCurrency, ClientProxyError>
    
    func dismissRewardsIntimation()
    
    // MARK: - ZERO MESSENGER INVITE
    
    var messengerInvitePublisher: CurrentValuePublisher<ZeroMessengerInvite, Never> { get }
    
    @discardableResult func loadZeroMessengerInvite() async -> Result<Void, ClientProxyError>
    
    // MARK: - ZERO CREATE ACCOUNT
    
    func isProfileCompletionRequired() async -> Bool
    
    func completeUserAccountProfile(avatar: MediaInfo?, displayName: String, inviteCode: String) async -> Result<Void, ClientProxyError>
    
    func deleteUserAccount() async -> Result<Void, ClientProxyError>
    
    // MARK: - ZERO USER
    
    var directMemberZeroProfilePublisher: CurrentValuePublisher<ZMatrixUser?, Never> { get }
    var zeroCurrentUserPublisher: CurrentValuePublisher<ZCurrentUser, Never> { get }
    var homeRoomSummariesUsersPublisher: CurrentValuePublisher<[ZMatrixUser], Never> { get }
        
    func zeroProfile(userId: String) async
    
    func zeroProfiles(userIds: Set<String>) async
    
    func checkAndLinkZeroUser() async
    
    func fetchZCurrentUser()
    
    // MARK: - ZERO FEED
    
    func fetchZeroFeeds(channelZId: String?, following: Bool, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError>
    
    func fetchFeedDetails(feedId: String) async -> Result<ZPost, ClientProxyError>
    
    func fetchFeedReplies(feedId: String, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError>
    
    func addMeowsToFeed(feedId: String, amount: Int) async -> Result<ZPost, ClientProxyError>
    
    func postNewFeed(channelZId: String, content: String, replyToPost: String?, mediaFile: URL?) async -> Result<Void, ClientProxyError>
    
    // MARK: - ZERO FEED USER
    
    func fetchFeedUserProfile(userZId: String) async -> Result<ZPostUserProfile, ClientProxyError>
    
    func fetchUserFeeds(userId: String, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError>
    
    func fetchFeedUserFollowingStatus(userId: String) async -> Result<ZPostUserFollowingStatus, ClientProxyError>
    
    func followFeedUser(userId: String) async -> Result<Void, ClientProxyError>
    
    func unFollowFeedUser(userId: String) async -> Result<Void, ClientProxyError>
    
    // MARK: - ZERO CHANNEL
    
    func fetchUserZIds() async -> Result<[String], ClientProxyError>
    
    func joinChannel(roomAliasOrId: String) async -> Result<String, ClientProxyError>
    
    // MARK: - ZERO WALLET
    
    func initializeThirdWebWalletForUser() async -> Result<Void, ClientProxyError>
    
    func getWalletTokenBalances(walletAddress: String, nextPage: NextPageParams?) async -> Result<ZWalletTokenBalances, ClientProxyError>
    
    func getWalletNFTs(walletAddress: String, nextPage: NextPageParams?) async -> Result<ZWalletNFTs, ClientProxyError>
    
    func getWalletTransactions(walletAddress: String, nextPage: TransactionNextPageParams?) async -> Result<ZWalletTransactions, ClientProxyError>
    
    func transferToken(senderWalletAddress: String, recipientWalletAddress: String, amount: String, tokenAddress: String) async -> Result<ZWalletTransactionResponse, ClientProxyError>
    
    func transferNFT(senderWalletAddress: String, recipientWalletAddress: String, tokenId: String, nftAddress: String) async -> Result<ZWalletTransactionResponse, ClientProxyError>
    
    func getTransactionReceipt(transactionHash: String) async -> Result<ZWalletTransactionReceipt, ClientProxyError>
    
    func searchTransactionRecipient(query: String) async -> Result<[WalletRecipient], ClientProxyError>
    
    func claimRewards(userWalletAddress: String) async -> Result<String, ClientProxyError>
    
    func getTokenInfo(tokenAddress: String) async -> Result<ZWalletTokenInfo, ClientProxyError>
    
    func getTokenBalance(tokenAddress: String) async -> Result<ZWalletTokenBalance, ClientProxyError>
    
    // MARK: - ZERO STAKING
    
    func getTotalStaked(poolAddress: String) async -> Result<String, ClientProxyError>
    
    func getStakingConfig(poolAddress: String) async -> Result<ZStackingConfig, ClientProxyError>
    
    func getStakerStatusInfo(userWalletAddress: String, poolAddress: String) async -> Result<ZStakingStatus, ClientProxyError>
    
    func getStakeRewardsInfo(userWalletAddress: String, poolAddress: String) async -> Result<ZStakingUserRewardsInfo, ClientProxyError>
    
    func getStakingToken(poolAddress: String) async -> Result<ZWalletStakingToken, ClientProxyError>
    
    func getRewardsToken(poolAddress: String) async -> Result<ZWalletStakingRewardsToken, ClientProxyError>
    
    // MARK: - ZERO METADATA
    
    func getLinkPreviewMetaData(url: String) async -> Result<ZLinkPreview, ClientProxyError>
    
    func getPostMediaInfo(mediaId: String) async -> Result<ZPostMedia, ClientProxyError>
    
    func fetchYoutubeLinkMetaData(youtubrUrl: String) async -> Result<ZLinkPreview, ClientProxyError>
    
    func loadFileFromUrl(_ remoteUrl: URL, key: String) async throws -> Result<URL, ClientProxyError>
    
    func loadFileFromMediaId(_ mediaId: String, key: String) async throws -> Result<URL, ClientProxyError>
}
