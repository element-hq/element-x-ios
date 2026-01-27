//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    
    case invalidMedia
    case invalidServerName
    case invalidResponse
    case failedUploadingMedia(ErrorKind)
    case roomPreviewIsPrivate
    case failedRetrievingUserIdentity
    case failedResolvingRoomAlias
    case roomNotInLocalStore
    case invalidInvite
}

enum SlidingSyncConstants {
    static let maximumVisibleRangeSize = 30
}

enum CreateRoomAccessType: Equatable {
    case `public`
    case spaceMembers(spaceID: String)
    case askToJoinWithSpaceMembers(spaceID: String)
    case askToJoin
    case `private`
    
    var isVisibilityPrivate: Bool {
        switch self {
        case .private, .spaceMembers, .askToJoinWithSpaceMembers:
            true
        case .public, .askToJoin:
            false
        }
    }
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

/// The `Decodable` conformance is just for the purpose of migration
enum TimelineMediaVisibility: Decodable {
    case always
    case privateOnly
    case never
}

// sourcery: AutoMockable
protocol ClientProxyProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> { get }
    
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> { get }
    
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> { get }
    
    var homeserverReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> { get }
    
    var userID: String { get }

    var deviceID: String? { get }

    var homeserver: String { get }
    
    var canDeactivateAccount: Bool { get }
    
    var userIDServerName: String? { get }
    
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> { get }

    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> { get }

    /// We delay fetching this until after the first sync. Nil until then
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> { get }
    
    var timelineMediaVisibilityPublisher: CurrentValuePublisher<TimelineMediaVisibility, Never> { get }
    
    var hideInviteAvatarsPublisher: CurrentValuePublisher<Bool, Never> { get }
    
    var pusherNotificationClientIdentifier: String? { get }
    
    var mediaLoader: MediaLoaderProtocol { get }
    
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
    
    var spaceService: SpaceServiceProxyProtocol { get }
    
    var isReportRoomSupported: Bool { get async }
    
    var isLiveKitRTCSupported: Bool { get async }
    
    var isLoginWithQRCodeSupported: Bool { get async }
    
    var maxMediaUploadSize: Result<UInt, ClientProxyError> { get async }
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError>
    
    func hasDevicesToVerifyAgainst() async -> Result<Bool, ClientProxyError>
    
    func startSync()

    func stopSync()
    
    func stopSync(completion: (() -> Void)?) // Hopefully this will become async once we get SE-0371.
    
    func expireSyncSessions() async
        
    func accountURL(action: AccountManagementAction) async -> URL?
    
    func directRoomForUserID(_ userID: String) -> Result<String?, ClientProxyError>
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError>
    
    func createRoom(name: String,
                    topic: String?,
                    accessType: CreateRoomAccessType,
                    isSpace: Bool,
                    userIDs: [String],
                    avatarURL: URL?,
                    aliasLocalPart: String?) async -> Result<String, ClientProxyError>
    
    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError>
    
    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError>
    
    func knockRoom(_ roomID: String, via: [String], message: String?) async -> Result<Void, ClientProxyError>
    
    func knockRoomAlias(_ roomAlias: String, message: String?) async -> Result<Void, ClientProxyError>
    
    func canJoinRoom(with rules: [AllowRule]) -> Bool
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError>
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyType?
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError>
    
    func roomSummaryForIdentifier(_ identifier: String) -> RoomSummary?
    
    func roomSummaryForAlias(_ alias: String) -> RoomSummary?
    
    /// Will only work for rooms that are in our room list/local store
    func reportRoomForIdentifier(_ identifier: String, reason: String) async -> Result<Void, ClientProxyError>
    
    @discardableResult func loadUserDisplayName() async -> Result<Void, ClientProxyError>
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError>

    @discardableResult func loadUserAvatarURL() async -> Result<Void, ClientProxyError>
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError>
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError>
    
    func linkNewDeviceService() -> LinkNewDeviceServiceProtocol
    
    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError>
    
    func logout() async

    func setPusher(with configuration: PusherConfiguration) async throws
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError>
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError>
    
    func isAliasAvailable(_ alias: String) async -> Result<Bool, ClientProxyError>
    
    @discardableResult func clearCaches() async -> Result<Void, ClientProxyError>
    
    @discardableResult func optimizeStores() async -> Result<Void, ClientProxyError>
    
    func storeSizes() async -> Result<StoreSizes, ClientProxyError>
    
    func fetchMediaPreviewConfiguration() async -> Result<MediaPreviewConfig?, ClientProxyError>

    // MARK: - Ignored users
    
    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    // MARK: - Recently visited rooms
    
    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError>
    
    func recentlyVisitedRooms(filter: (JoinedRoomProxyProtocol) -> Bool) async -> [JoinedRoomProxyProtocol]
    func recentConversationCounterparts() async -> [UserProfileProxy]
    
    // MARK: - Crypto
    
    func ed25519Base64() async -> String?
    func curve25519Base64() async -> String?
    
    func pinUserIdentity(_ userID: String) async -> Result<Void, ClientProxyError>
    func withdrawUserIdentityVerification(_ userID: String) async -> Result<Void, ClientProxyError>
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError>
    
    func userIdentity(for userID: String, fallBackToServer: Bool) async -> Result<UserIdentityProxyProtocol?, ClientProxyError>
    
    // MARK: - Moderation & Safety
    
    func setTimelineMediaVisibility(_ value: TimelineMediaVisibility) async -> Result<Void, ClientProxyError>
    func setHideInviteAvatars(_ value: Bool) async -> Result<Void, ClientProxyError>
}
